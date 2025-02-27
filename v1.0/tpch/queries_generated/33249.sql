WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal AND level < 3
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    r.r_name AS region, 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(SUBSTRING(s.s_name, 1, 10)) AS avg_supplier_name,
    COUNT(DISTINCT ps.ps_partkey) FILTER (WHERE ps.ps_availqty > 0) AS available_parts,
    COALESCE(MAX(o.total_sales), 0) AS max_order_sales,
    CASE
        WHEN COUNT(DISTINCT s.s_suppkey) > 5 THEN 'High supply'
        ELSE 'Low supply'
    END AS supply_status
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartSupplier ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN OrderSummary o ON s.s_suppkey = o.o_orderkey
LEFT JOIN Customer c ON s.s_nationkey = c.c_nationkey
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey
WHERE r.r_name LIKE 'Amer%' 
AND l.l_shipmode IN ('TRUCK', 'AIR')
AND l.l_returnflag IS NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(l.l_discount) IS NOT NULL
ORDER BY total_revenue DESC
LIMIT 10;
