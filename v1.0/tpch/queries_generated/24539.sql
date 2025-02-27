WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderdate < DATEADD(day, 30, oh.o_orderdate)
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
RegionNation AS (
    SELECT r.r_regionkey, n.n_nationkey, n.n_name
    FROM region r
    LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
)
SELECT
    c.c_custkey,
    cs.order_count,
    cs.avg_order_value,
    ss.total_supply_cost,
    lh.net_revenue,
    rn.n_name AS nation_name,
    CASE WHEN cs.order_count IS NOT NULL THEN 'Customer Active' ELSE 'No Orders' END AS customer_status,
    COALESCE(lh.net_revenue, 0) AS adjusted_net_revenue,
    DENSE_RANK() OVER (PARTITION BY rn.n_name ORDER BY cs.avg_order_value DESC) AS avg_order_rank
FROM CustomerStats cs
LEFT JOIN SupplierStats ss ON ss.s_suppkey = (
    SELECT ps.ps_suppkey FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 100) 
    LIMIT 1
)
LEFT JOIN LineItemStats lh ON lh.l_orderkey = (
    SELECT o.o_orderkey FROM orders o 
    WHERE o.o_totalprice = (SELECT MAX(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
)
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
JOIN RegionNation rn ON rn.r_regionkey = r.r_regionkey
WHERE (cs.order_count IS NOT NULL OR ss.total_supply_cost IS NOT NULL) 
AND (r.r_name LIKE '%North%' OR r.r_name IS NULL)
ORDER BY c.c_custkey DESC;
