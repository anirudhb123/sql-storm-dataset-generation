WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'Asia')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spending
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
), 
SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
FilteredLineItems AS (
    SELECT l.*, 
           CASE 
               WHEN l.l_discount > 0.05 THEN l.l_extendedprice * (1 - l.l_discount)
               ELSE l.l_extendedprice
           END AS final_price
    FROM lineitem l
    WHERE l.l_shipdate > '1997-01-01'
)
SELECT 
    nh.n_name AS nation_name, 
    SUM(co.order_count) AS total_customers,
    SUM(ps.total_cost) AS total_supplier_cost,
    AVG(ro.o_totalprice) AS average_order_price,
    COUNT(DISTINCT li.l_orderkey) AS total_line_items,
    COALESCE(AVG(li.final_price), 0) AS avg_final_price
FROM NationHierarchy nh
LEFT JOIN CustomerOrders co ON nh.n_nationkey = co.c_custkey
LEFT JOIN SupplierSummary ps ON nh.n_regionkey = ps.s_suppkey
LEFT JOIN RankedOrders ro ON co.c_custkey = ro.o_orderkey
LEFT JOIN FilteredLineItems li ON ro.o_orderkey = li.l_orderkey
GROUP BY nh.n_name
HAVING AVG(li.final_price) IS NOT NULL
ORDER BY total_customers DESC;