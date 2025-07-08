WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT os.o_orderkey
    FROM OrderSummary os
    WHERE os.revenue_rank <= 10
)

SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
    MAX(l.l_tax) AS max_tax,
    CASE 
        WHEN SUM(l.l_discount) IS NULL THEN 'No Discounts'
        ELSE 'Discounts Available'
    END AS discount_status
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
GROUP BY p.p_name
HAVING COUNT(DISTINCT ps.ps_suppkey) > 5
ORDER BY total_quantity DESC
LIMIT 20;
