WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS order_level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
      AND o.o_orderstatus = 'O'
),

SupplierProducts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty,
           SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),

CustomerOverview AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           CASE WHEN c.c_acctbal IS NULL THEN 'No Balance' 
                ELSE 'Balance Available' END AS balance_status
    FROM customer c
)

SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, 
       COALESCE(SP.total_avail_qty, 0) AS supplier_avail_qty,
       COUNT(DISTINCT c.c_custkey) AS unique_customers,
       SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) END) AS discounted_revenue,
       ROW_NUMBER() OVER (PARTITION BY oh.o_orderdate ORDER BY oh.o_totalprice DESC) AS order_rank
FROM OrderHierarchy oh
LEFT JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN SupplierProducts SP ON l.l_partkey = SP.ps_partkey AND l.l_suppkey = SP.ps_suppkey
LEFT JOIN CustomerOverview c ON oh.o_custkey = c.c_custkey
WHERE oh.o_totalprice > (
    SELECT AVG(o_totalprice) FROM orders
    WHERE o_orderstatus = 'O'
)
AND NOT EXISTS (
    SELECT 1 FROM lineitem l2 
    WHERE l2.l_orderkey = oh.o_orderkey 
      AND l2.l_returnflag = 'R'
)
GROUP BY oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, SP.total_avail_qty
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY oh.o_orderdate DESC, oh.o_totalprice DESC;
