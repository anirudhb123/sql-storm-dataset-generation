
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000

    UNION ALL

    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal < sh.s_acctbal
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name AS cust_name, c.c_acctbal AS cust_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           CASE 
               WHEN p.p_retailprice > 100 THEN 'Expensive'
               ELSE 'Affordable'
           END AS price_category
    FROM part p
    WHERE p.p_size IN (1, 2, 3) OR p.p_brand LIKE 'Brand%'
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_orderkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
)
SELECT th.cust_name, th.cust_acctbal, s.s_name AS supplier_name,
       SUM(os.total_revenue) AS total_order_revenue, 
       MAX(ps.price_category) AS part_price_category
FROM TopCustomers th
LEFT JOIN SupplierStats s ON th.c_custkey = s.s_suppkey
LEFT JOIN OrderStats os ON th.c_custkey = os.o_orderkey
JOIN FilteredParts ps ON ps.p_partkey = os.o_orderkey
WHERE th.rn <= 5
GROUP BY th.cust_name, th.cust_acctbal, s.s_name
HAVING SUM(os.total_revenue) IS NOT NULL 
ORDER BY total_order_revenue DESC
LIMIT 10;
