WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) 
        FROM supplier s2 
        WHERE s2.s_nationkey = s.s_nationkey
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal < cte.s_acctbal * 1.1
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
DiscountedOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.1 AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    pp.p_name AS part_name,
    COALESCE(SUM(l.l_extendedprice), 0) AS total_sales,
    COALESCE(d.total_orders, 0) AS total_orders,
    COALESCE(d.total_revenue, 0) AS total_revenue,
    (COUNT(DISTINCT ps.ps_suppkey) FILTER (WHERE ps.ps_availqty < 100) OVER ()) AS low_supply_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN DiscountedOrders d ON c.c_custkey = d.o_custkey
JOIN PartDetails pp ON pp.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = ps.ps_partkey
    )
)
LEFT JOIN lineitem l ON l.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = c.c_custkey AND o.o_orderstatus IN ('O', 'F')
)
GROUP BY r.r_name, n.n_name, c.c_name, pp.p_name, d.total_orders, d.total_revenue
HAVING SUM(COALESCE(l.l_extendedprice, 0)) > 1000 OR COUNT(DISTINCT l.l_linenumber) > 5
ORDER BY r.r_name, n.n_name, total_sales DESC;
