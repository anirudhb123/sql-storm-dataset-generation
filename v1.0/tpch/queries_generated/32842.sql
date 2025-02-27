WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
AggregatedLineItems AS (
    SELECT l_orderkey, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
           COUNT(*) AS item_count
    FROM lineitem
    GROUP BY l_orderkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT OH.o_orderkey,
       COALESCE(AL.total_revenue, 0) AS order_revenue,
       COALESCE(AL.item_count, 0) AS order_item_count,
       SC.s_name AS supplier_name,
       SC.avg_supply_cost AS supplier_avg_cost,
       TC.c_name AS customer_name,
       TC.total_spent AS customer_total_spent,
       ROW_NUMBER() OVER (PARTITION BY OH.o_orderkey ORDER BY OH.o_orderdate DESC) AS order_rank
FROM OrderHierarchy OH
LEFT JOIN AggregatedLineItems AL ON OH.o_orderkey = AL.l_orderkey
LEFT JOIN SupplierDetails SC ON AL.item_count > 0 AND SC.total_available > 0
LEFT JOIN TopCustomers TC ON OH.o_custkey = TC.c_custkey
WHERE OH.level <= 5
ORDER BY OH.o_orderkey, order_rank DESC;
