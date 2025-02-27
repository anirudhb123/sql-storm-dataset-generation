WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_brand, 1 AS level
    FROM part
    WHERE p_size > 10

    UNION ALL

    SELECT p.p_partkey, p.p_name, p.p_brand, ph.level + 1
    FROM part p
    INNER JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey
    WHERE ph.level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nationname
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
)

SELECT 
    ph.p_name,
    ph.p_brand,
    sd.s_name,
    sd.nationname,
    ts.total_revenue,
    CASE 
        WHEN ts.total_revenue IS NULL THEN 'No Sales'
        ELSE 'Sales Found'
    END AS revenue_status,
    ROW_NUMBER() OVER (PARTITION BY sd.nationname ORDER BY ts.total_revenue DESC) AS sales_rank
FROM PartHierarchy ph
LEFT JOIN partsupp ps ON ph.p_partkey = ps.ps_partkey
LEFT JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN TotalSales ts ON ts.l_orderkey = ps.ps_partkey
WHERE 
    (sd.s_acctbal IS NOT NULL OR sd.s_acctbal > 5000)
    AND (ph.p_brand LIKE 'Brand%')
    AND ts.total_revenue > 10000
ORDER BY revenue_status DESC, ts.total_revenue DESC;
