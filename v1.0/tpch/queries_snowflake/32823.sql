WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_clerk, 0 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
  
    UNION ALL
  
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_clerk, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus <> 'O'
),
SupplierAggregate AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COALESCE(SA.total_cost, 0) AS supplier_cost,
    COALESCE(CO.order_count, 0) AS customer_order_count,
    RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank,
    CASE 
        WHEN o.level IS NULL THEN 'No orders'
        ELSE CONCAT('Orders at level ', o.level)
    END AS order_status
FROM part p
LEFT JOIN SupplierAggregate SA ON SA.ps_partkey = p.p_partkey
LEFT JOIN CustomerOrders CO ON CO.c_custkey = p.p_partkey /* Assuming partkey relations to custkey for demo */
LEFT JOIN OrderHierarchy o ON p.p_partkey = o.o_orderkey /* Assuming partkey boundaries */ 
WHERE p.p_size > 25 AND p.p_retailprice < 500
ORDER BY p.p_retailprice DESC, p.p_name ASC;
