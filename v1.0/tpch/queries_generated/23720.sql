WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
), 
OrderLineItemStats AS (
    SELECT l.l_orderkey,
           COUNT(*) AS total_lines,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           SUM(l.l_tax) AS total_tax
    FROM lineitem l
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY l.l_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, 
           n.n_name,
           COALESCE(SUM(ols.total_revenue), 0) AS national_revenue
    FROM nation n
    LEFT JOIN orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    LEFT JOIN OrderLineItemStats ols ON o.o_orderkey = ols.l_orderkey
    GROUP BY n.n_nationkey, n.n_name
),
TopRegions AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           SUM(n.national_revenue) AS region_revenue
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN NationRevenue nr ON n.n_nationkey = nr.n_nationkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING SUM(n.national_revenue) > 100000
),
SuppliersWithHighBal AS (
    SELECT rs.s_suppkey, 
           rs.s_name,
           rs.s_acctbal
    FROM RankedSuppliers rs
    WHERE rs.rn <= 3
)

SELECT DISTINCT 
    pr.p_partkey,
    pr.p_name,
    pr.p_retailprice,
    r.r_name AS region_name,
    swhb.s_name AS top_supplier_name,
    CASE 
        WHEN nw.national_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(nw.national_revenue AS VARCHAR)
    END AS national_revenue,
    COALESCE(nw.national_revenue, 0) * 0.1 AS revenue_impact
FROM part pr
LEFT JOIN partsupp ps ON pr.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN NationRevenue nw ON n.n_nationkey = nw.n_nationkey
JOIN SuppliersWithHighBal swhb ON s.s_suppkey = swhb.s_suppkey
FULL OUTER JOIN TopRegions tr ON r.r_regionkey = tr.r_regionkey
WHERE pr.p_size IS NULL AND (pr.p_comment LIKE '%key%' OR tr.region_revenue IS NOT NULL)
ORDER BY revenue_impact DESC NULLS LAST;
