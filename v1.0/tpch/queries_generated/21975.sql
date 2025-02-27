WITH RECURSIVE TopRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(DISTINCT n.n_nationkey) > 2
),
SupplierStatistics AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost, 
           COUNT(DISTINCT p.p_partkey) AS part_count, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus IN ('O', 'F')
),
FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
           COUNT(l.l_linenumber) AS line_count
    FROM lineitem l
    WHERE l.l_shipdate > '2023-01-01'
    GROUP BY l.l_orderkey
)
SELECT 
    r.r_name AS region_name,
    ss.s_name AS supplier_name,
    ce.c_name AS customer_name,
    cf.net_sales AS total_sales,
    cf.line_count AS total_line_items,
    COALESCE(SUM(CASE WHEN cs.order_rank = 1 THEN cs.o_totalprice ELSE 0 END), 0) AS latest_order_value
FROM TopRegions r
FULL OUTER JOIN SupplierStatistics ss ON ss.part_count > 10
JOIN CustomerOrders ce ON ce.o_orderkey IN (
    SELECT l.l_orderkey FROM FilteredLineItems l WHERE l.line_count > 5
)
LEFT JOIN FilteredLineItems cf ON cf.l_orderkey = ce.o_orderkey
GROUP BY r.r_name, ss.s_name, ce.c_name
ORDER BY r.r_name, total_sales DESC
LIMIT 100;
