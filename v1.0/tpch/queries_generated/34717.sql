WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 1 AS level
    FROM customer
    WHERE c_acctbal > 5000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE c.c_acctbal > (ch.c_acctbal * 0.85)
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
),
PartSuppInfo AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT
    p.p_name, 
    p.p_brand, 
    ps.total_avail_qty, 
    ps.avg_supply_cost, 
    coalesce(l.total_qty, 0) AS total_ordered_qty,
    c.c_name AS customer_name,
    RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN PartSuppInfo ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CustomerHierarchy c ON c.c_custkey = (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
LEFT JOIN RankedOrders ro ON l.l_orderkey = ro.o_orderkey
GROUP BY p.p_partkey, p.p_name, p.p_brand, ps.total_avail_qty, ps.avg_supply_cost, c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY price_rank, total_ordered_qty DESC;
