WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey < oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierAggregate AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(lo.total_revenue), 0) AS total_revenue, COUNT(lo.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN LineItemDetails lo ON o.o_orderkey = lo.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, s.s_name, s.s_acctbal,
           CASE WHEN s.s_acctbal IS NULL THEN 'No Balance' ELSE 'Has Balance' END AS balance_status
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT co.c_custkey, co.c_name, 
       COALESCE(co.total_revenue, 0) AS total_revenue, 
       ps.p_name, ps.s_name, 
       ps.balance_status,
       oh.order_rank
FROM CustomerOrders co
LEFT JOIN OrderHierarchy oh ON co.c_custkey = oh.o_orderdate
LEFT JOIN PartSupplier ps ON ps.p_partkey = (SELECT ps_partkey FROM partsupp ORDER BY RANDOM() LIMIT 1)
WHERE co.total_revenue > 1000 OR co.order_count > 5
ORDER BY co.total_revenue DESC, oh.order_rank ASC
LIMIT 50;
