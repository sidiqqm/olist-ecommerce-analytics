# Business Understanding — Olist E-Commerce Analytics

**Project**: End-to-End Data Analyst Portfolio
**Dataset**: Brazilian E-Commerce Public Dataset by Olist
**Period**: September 2016 – September 2018
**Author**: [Your Name]
**Last Updated**: [Date]

---

## 1. Business Background

Olist adalah marketplace e-commerce terbesar di Brazil yang beroperasi 
sebagai marketplace aggregator. Alih-alih menjual produk sendiri, Olist 
menghubungkan merchant kecil dan menengah (seller) dengan channel distribusi 
besar seperti Americanas, Shoptime, Submarino, dan Casas Bahia.

**Model Bisnis Olist:**
- Seller mendaftar dan membayar subscription fee
- Olist mendaftarkan produk seller ke multiple marketplace
- Ketika ada order, seller bertanggung jawab atas fulfillment
- Olist mengelola payment processing dan hubungan dengan marketplace

**Konteks Pasar:**
- Brazil adalah pasar e-commerce terbesar di Amerika Latin
- Periode dataset (2016–2018) merupakan fase pertumbuhan agresif e-commerce Brazil
- Penetrasi internet Brazil tumbuh dari ~60% (2016) ke ~70% (2018)

---

## 2. Stakeholder Mapping

| Stakeholder | Role | Kebutuhan Utama | Dashboard Audience |
|-------------|------|-----------------|--------------------|
| CEO / C-Level | Decision Maker | Revenue growth, strategic KPIs | Executive Dashboard |
| Head of Sales | Influencer | GMV, seller growth, category | Executive + Trend |
| Head of Operations | Influencer | Delivery SLA, efficiency | Operational Dashboard |
| Head of CX | Influencer | Review score, CLV, retention | Detail Dashboard |
| Marketing Team | User | RFM, cohort, regional | Detail Dashboard |
| Seller Success | User | Seller performance tier | Operational + Detail |

---

## 3. Business Problem Statement

Olist mengalami pertumbuhan volume order yang signifikan dari 2016 hingga 
2018, namun belum memiliki visibility yang memadai terhadap driver utama 
pertumbuhan revenue, pola perilaku customer, performa seller, dan efisiensi 
operasional pengiriman. Tanpa pemahaman mendalam terhadap metrik-metrik ini, 
manajemen tidak dapat mengambil keputusan strategis yang tepat untuk 
mempertahankan pertumbuhan, meningkatkan customer satisfaction, dan 
mengoptimalkan ekosistem seller.

---

## 4. Business Objectives (SMART)

| ID | Objective | Metric | Timeline |
|----|-----------|--------|----------|
| O1 | Analisis performa revenue & GMV | GMV growth rate | Sep 2016–Sep 2018 |
| O2 | Pahami pola perilaku customer | Retention rate, CLV | Seluruh periode |
| O3 | Evaluasi performa seller | Revenue per seller, tier | Seluruh periode |
| O4 | Ukur efisiensi operasional | On-time delivery rate | Seluruh periode |
| O5 | Analisis customer satisfaction | Average review score | Seluruh periode |
| O6 | Identifikasi kategori & regional | Revenue by category/state | Seluruh periode |

---

## 5. Business Questions

### Revenue & GMV
- BQ-01: Bagaimana tren GMV dan total order bulanan?
- BQ-02: Bagaimana tren Average Order Value (AOV)?
- BQ-03: Apa distribusi dan tren metode pembayaran?

### Customer
- BQ-04: Berapa proporsi new vs returning customer?
- BQ-05: Bagaimana distribusi Customer Lifetime Value?
- BQ-06: Bagaimana hasil RFM Segmentation?
- BQ-07: Bagaimana cohort retention rate?

### Seller
- BQ-08: Siapa top sellers dan seberapa terkonsentrasi revenue?
- BQ-09: Bagaimana distribusi seller performance tier?
- BQ-10: Seller state mana yang berkinerja terbaik/terburuk?

### Delivery
- BQ-11: Berapa On-Time Delivery Rate per state?
- BQ-12: Berapa gap estimated vs actual delivery?
- BQ-13: Bagaimana korelasi jarak dengan delivery duration & review?

### Satisfaction
- BQ-14: Apa pola order dengan review score rendah vs tinggi?

### Product & Regional
- BQ-15: Kategori mana yang memiliki GMV tinggi, growth cepat, score baik?

---

## 6. KPI Definition

# KPI Master Table

| Category | KPI Name | Formula | Unit | Target / Benchmark |
|---|---|---|---|---|
| **Revenue & GMV** | **Gross Merchandise Value (GMV)** | `SUM(price) + SUM(freight_value)` per period | BRL | Monitor trend |
| **Revenue & GMV** | **Average Order Value (AOV)** | `GMV / Total Orders` | BRL | > BRL 150 |
| **Revenue & GMV** | **Revenue Growth Rate (MoM)** | `(GMV_curr - GMV_prev) / GMV_prev × 100` | % | > 10% MoM |
| **Customer** | **Repeat Purchase Rate** | `Customers with >1 order / Total unique customers × 100` | % | > 15% |
| **Customer** | **Customer Lifetime Value (CLV)** | `SUM(order_value)` per customer across all orders | BRL | > BRL 300 |
| **Customer** | **New Customer Rate** | `New customers / Total customers in period × 100` | % | Monitor |
| **Operational** | **On-Time Delivery Rate (OTDR)** | `Orders delivered ≤ estimated date / Total delivered × 100` | % | > 90% |
| **Operational** | **Average Delivery Duration** | `AVG(order_delivered_customer - order_purchase_timestamp)` | Days | < 12 days |
| **Operational** | **Delivery Gap (Est. vs Actual)** | `AVG(actual_delivery - estimated_delivery)` | Days | ≤ 0 days *(early/on time)* |
| **Seller** | **Active Seller Rate** | `Sellers with ≥1 order in period / Total registered sellers × 100` | % | > 70% |
| **Seller** | **Revenue Concentration (Pareto)** | `% GMV dari top 20% seller` | % | < 80% *(healthy distribution)* |
| **Satisfaction** | **Average Review Score** | `AVG(review_score)` | 1–5 | ≥ 4.0 |
| **Satisfaction** | **Review Response Rate** | `Orders with review / Total delivered orders × 100` | % | > 60% |
| **Satisfaction** | **Negative Review Rate (NRR)** | `Reviews score ≤ 2 / Total reviews × 100` | % | < 10% |

---

## 7. Success Metrics

# Success Metrics & Acceptance Criteria

| ID | Kriteria | Target |
|---|---|---|
| **SM-01** | Seluruh 15 business questions terjawab dengan data | **100%** |
| **SM-02** | Dashboard dapat dibaca tanpa penjelasan verbal | Uji dengan stakeholder non-teknis |
| **SM-03** | Minimal 10 business insight dengan format lengkap | **≥ 10 insight** |
| **SM-04** | Minimal 10 actionable recommendation | **≥ 10 rekomendasi** |
| **SM-05** | Forecasting memiliki error MAPE < 20% | **MAPE < 20%** |
| **SM-06** | Data quality coverage > 95% untuk kolom kritis | **> 95%** |
| **SM-07** | Executive Summary dapat dipahami non-teknis | **Tidak ada jargon teknis** |

---

## 8. Scope

### In Scope
- Orders: Sep 2016 – Sep 2018
- Geography: Seluruh Brazil (26 states + DF)
- Metrics: Revenue, Customer, Seller, Delivery, Satisfaction, Category, Regional
- Tools: BigQuery, Python, Power BI

### Out of Scope
- Real-time data
- Competitor analysis
- Profit/margin analysis (tidak ada COGS)
- Customer demographics
- Machine Learning

---

## 9. Assumptions

| ID | Asumsi | Justifikasi |
|----|--------|-------------|
| A-01 | 1 customer_unique_id = 1 individual customer | Dataset definition |
| A-02 | Harga adalah harga final | Tidak ada field diskon |
| A-03 | freight_value termasuk GMV | Bagian dari ekosistem revenue |
| A-04 | Non-review = tidak ada review | Tidak bisa asumsikan sentimen |
| A-05 | Timezone = America/Sao_Paulo | Mayoritas order dari SP |
| A-06 | Canceled orders dieksklusi dari GMV | Bukan revenue aktual |
| A-07 | Seller tanpa order = tidak aktif | Tidak ada data registrasi terpisah |
| A-08 | Geolocation via 5-digit zip prefix | Sesuai struktur data |

---

## 10. Risks & Limitations

| ID | Risiko | Dampak | Mitigasi |
|----|--------|--------|----------|
| R-01 | Data mungkin di-anonymize | Medium | Fokus pattern, bukan individual |
| R-02 | Missing values pada tanggal delivery | High | Dokumentasi exclusions |
| R-03 | Tidak ada data COGS | High | Fokus GMV, bukan profit |
| R-04 | Repeat rate mungkin sangat rendah | Medium | Interpretasi konteks market |
| R-05 | Geolocation kurang akurat di zip level | Low | Gunakan state-level |
| R-06 | Review score bisa bias (selection bias) | Medium | Cantumkan caveat |
| R-07 | Data 2 tahun → forecast terbatas | Medium | Proyeksi max 6 bulan |
| R-08 | Dataset berakhir 2018 | High | Cantumkan date scope |