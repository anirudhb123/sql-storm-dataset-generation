WITH RECURSIVE OrdersHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    
    UNION ALL

    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, h.level + 1
    FROM orders oh
    JOIN OrdersHierarchy h ON oh.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = h.o_orderkey)
    WHERE oh.o_orderstatus = 'O'
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           MAX(l.l_extendedprice - l.l_extendedprice * l.l_discount) AS max_profit,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 500
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_name, p.p_retailprice, ps.total_supply_cost, cs.total_orders,
       CASE 
           WHEN cs.total_orders IS NULL THEN 'No Orders'
           ELSE CAST(cs.total_orders AS VARCHAR)
       END AS order_status,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS ranking,
       s.s_name AS supplier_name
FROM PartStatistics p
LEFT JOIN SupplierStats ps ON p.supplier_count = ps.num_parts
LEFT JOIN CustomerOrders cs ON cs.total_orders > 0
LEFT JOIN supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
WHERE p.max_profit > 1000
ORDER BY p.p_name, ps.total_supply_cost DESC
LIMIT 50;
