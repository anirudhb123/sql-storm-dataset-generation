WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 20000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, cs.level + 1
    FROM supplier s
    JOIN CTE_Supplier cs ON s.s_suppkey = (SELECT ps.ps_suppkey
                                             FROM partsupp ps
                                             WHERE ps.ps_partkey IN (SELECT p.p_partkey
                                                                     FROM part p
                                                                     WHERE p.p_retailprice > 50)
                                             ORDER BY ps.ps_supplycost DESC
                                             LIMIT 1)
    WHERE cs.level < 5
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, SUM(c.c_acctbal) AS total_acctbal
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name
    FROM orders o
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
),
LineItemMetrics AS (
    SELECT l.l_orderkey, COUNT(*) AS line_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           AVG(l.l_tax) AS avg_tax
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT
    rs.r_name,
    SUM(os.o_totalprice) AS total_order_value,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(lm.total_sales) AS total_lineitem_sales,
    ROUND(AVG(lm.avg_tax), 2) AS average_tax_rate
FROM RegionSummary rs
LEFT JOIN OrderSummary os ON rs.total_acctbal > 100000
LEFT JOIN LineItemMetrics lm ON lm.l_orderkey IN (SELECT o.o_orderkey
                                                    FROM orders o
                                                    WHERE o.o_orderstatus = 'O')
GROUP BY rs.r_name
HAVING SUM(os.o_totalprice) > 1000000
ORDER BY total_order_value DESC
LIMIT 10;
