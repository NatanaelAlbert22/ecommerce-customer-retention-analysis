# E-commerce Customer Retention Analysis

> Why is growth slowing down, and which customers are worth keeping?
> An end-to-end SQL and BI analysis of Brazilian e-commerce orders: revenue trends, cohort retention, and RFM customer segmentation.

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/natanael.albert/viz/OlistBrazilianEcommerceDataAnalysis/Dashboard1?publish=yes)**

![Dashboard preview](reports/dashboard_overview.png)

---

## Business Problem

The management team of an online marketplace noticed that revenue growth was slowing down. They wanted answers to three questions:

1. **When** did growth start to slow, and is it driven by fewer orders or lower order value?
2. **Do customers come back** after their first purchase, and how fast does that retention decay?
3. **Which customer segments** deserve retention budget, and which do not?

## Dataset

[Olist Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle): 9 relational tables covering orders, order items, customers, products, sellers, payments, reviews, and geolocation.

| Item | Detail |
|---|---|
| Orders analyzed | 98,198 (status `canceled` and `unavailable` excluded) |
| Unique customers | 94,983 (`customer_unique_id`) |
| Period | September 2016 – August 2018 (September 2018 excluded, see Limitations) |

**Data model:** see the entity-relationship diagram in [`reports/erd.png`](reports/erd.png).

> **Important data note:** in this dataset `customer_id` is unique *per order*, not per person. The real customer identity is `customer_unique_id`. All retention and RFM analysis uses `customer_unique_id`; using `customer_id` would make every customer look like a one-time buyer.

## Approach

1. **Data modeling:** loaded the 9 CSV files into DuckDB and mapped relationships between tables.
2. **Revenue analysis:** monthly revenue, cumulative revenue, and month-over-month growth using CTEs and window functions (`LAG`, `SUM() OVER`).
3. **Cohort retention:** grouped customers by first purchase month and tracked the share that purchased again in later months.
4. **RFM segmentation:** scored customers on Recency, Frequency, and Monetary value (`NTILE(5)`) and mapped them to business segments.
5. **Dashboard:** built an interactive dashboard in Tableau Public for non-technical stakeholders.

**Metric definitions**
- **Revenue** = `price + freight_value` per order item, summed per order.
- **Recency** = days between a customer's last order and the latest order date in the dataset.
- **Frequency** = number of distinct orders per customer.
- **Monetary** = total revenue per customer.

## Key Findings

**1. Revenue grew sharply through 2017, then plateaued in 2018 — it did not continue to grow, it stopped growing.**

Monthly revenue climbed from R$51k (October 2016) to a peak of R$1.17M in November 2017 (likely a Black Friday effect, with order volume jumping to 7,421 orders that month alone). From January to August 2018, revenue oscillated in a narrow band between roughly R$0.98M and R$1.16M with no clear upward trend — month-over-month growth alternated between small positive and negative swings (+17.7%, -0.9%, -10.9%, +1.9%, -4.1%). This is the slowdown the business team suspected: **growth did not reverse, it flattened.**

**2. Repeat purchases are extremely rare — this is the core retention problem.**

Across nearly every cohort, retention in the month immediately after first purchase sits **under 1%** (examples observed: 0.52% for the July 2017 cohort, 0.34% for the October 2016 cohort, 0.02% for the August 2018 cohort). The large majority of customers in this dataset buy exactly once and never return. This is a structural characteristic of the business, not a data error — see heatmap below.

![Cohort retention heatmap](reports/cohort_heatmap.png)

**3. RFM segmentation, with an important caveat about the Frequency score.**

| Segment | Customers | % of total |
|---|---|---|
| Loyal Customer | 35,366 | 37.2% |
| Regular | 19,248 | 20.3% |
| At Risk | 14,093 | 14.8% |
| Lost | 10,087 | 10.6% |
| New Customer | 8,659 | 9.1% |
| Champion | 7,530 | 7.9% |

At first glance, 37% "Loyal Customer" looks inconsistent with finding #2 (almost nobody repeat-purchases). This is explained in Limitations below — it is a real issue found during this analysis, not a hypothetical one.

## Business Recommendations

1. **Treat "second purchase" as the primary KPI, not overall retention curves.** Since the drop-off from 1st to 2nd purchase is this severe, a post-purchase incentive (discount on next order, reminder email at day 7–14) targeting first-time buyers has the largest realistic upside.
2. **Re-evaluate the RFM segments before using them for campaign targeting.** The Frequency score needs to be rebuilt with a rule-based approach (see Limitations) before "Loyal Customer" and "Champion" lists are trusted for marketing spend.
3. **Treat the 2018 plateau as the baseline to beat, not a one-off dip.** Since it held for 8 consecutive months, this looks structural (market saturation or competition) rather than seasonal noise, and likely needs a growth lever beyond organic repeat purchases, such as new-customer acquisition or expansion into new product categories.
4. **Do not over-invest in reactivating the Lost segment** until the Frequency scoring is fixed and this segment can be verified as genuinely low-value rather than an artifact of the scoring method.

## Limitations

- **RFM Frequency score is distorted by tied values.** Because the large majority of customers have `frequency = 1`, `NTILE(5)` — which splits by rank rather than value — spreads these one-time buyers across multiple buckets (1 through roughly 3–4) instead of grouping them all at the bottom. This likely explains why 37% of customers were classified as "Loyal Customer": a chunk of one-time buyers received a misleadingly high F score purely from how ties were broken, not from actual repeat behavior. **Fix for a future iteration:** replace `NTILE` on frequency with a rule-based score, e.g. `CASE WHEN frequency = 1 THEN 1 WHEN frequency = 2 THEN 3 ELSE 5 END AS f_score`.
- **September 2018 was excluded from the revenue trend** because the dataset only contains a single incomplete order for that month (R$166.46) — this is a data cutoff artifact, not a real one-month revenue collapse, and including it would badly distort any month-over-month comparison.
- **Low repeat-purchase rate is a property of the data**, not a modeling choice — most Olist customers bought only once in the dataset's timeframe.
- **Historical, observational data.** The analysis describes what happened; it does not prove which specific actions would cause customers to return.

## Repository Structure

```
ecommerce-customer-retention-analysis/
├── data/
│   ├── raw/              # Original Kaggle CSVs (not tracked by git)
│   └── processed/        # Query outputs used by the dashboard
├── notebooks/
│   ├── 00_setup_database.ipynb
│   └── 01_sql_analysis.ipynb
├── sql/
│   ├── 01_monthly_revenue.sql
│   ├── 02_cohort_retention.sql
│   └── 03_rfm_segmentation.sql
├── reports/              # ERD, heatmap, dashboard screenshots
├── requirements.txt
└── README.md
```

## Tech Stack

Python (pandas, DuckDB, seaborn, matplotlib) · SQL (CTEs, window functions, cohort analysis) · Tableau Public

## How to Reproduce

```bash
# 1. Clone and enter the repo
git clone https://github.com/NatanaelAlbert22/ecommerce-customer-retention-analysis.git
cd ecommerce-customer-retention-analysis

# 2. Create environment and install dependencies
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # Mac/Linux
pip install -r requirements.txt

# 3. Download the dataset from Kaggle into data/raw/
#    https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
```

4. Run `notebooks/00_setup_database.ipynb` to build the local DuckDB database.
5. Run `notebooks/01_sql_analysis.ipynb` to produce the analysis tables and export them to `data/processed/`.

The `.duckdb` database file is not committed; it is regenerated from the raw CSVs in step 4.

## Author

**ISI_NAMA_KAMU** · [LinkedIn](https://www.linkedin.com/in/natanael-albert/) · [GitHub](https://github.com/NatanaelAlbert22)