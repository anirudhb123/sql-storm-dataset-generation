WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS hierarchy_level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, oh.hierarchy_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
RankedLineItems AS (
    SELECT l.*, 
           ROW_NUMBER() OVER (PARTITION BY l_orderkey ORDER BY l_extendedprice DESC) AS price_rank,
           SUM(l_extendedprice) OVER (PARTITION BY l_orderkey) AS total_value
    FROM lineitem l
),
SupplierCost AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sc.total_cost, 0) AS total_supplier_cost,
    lo.total_value AS total_order_value,
    oh.hierarchy_level,
    co.total_spent,
    CASE 
        WHEN co.order_count > 10 THEN 'High Value'
        WHEN co.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM part p
LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
JOIN RankedLineItems lo ON p.p_partkey = lo.l_partkey AND lo.price_rank = 1
LEFT JOIN OrderHierarchy oh ON oh.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 1000)
LEFT JOIN CustomerOrders co ON co.c_custkey = oh.o_custkey
WHERE p.p_size BETWEEN 10 AND 30
AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_container IS NOT NULL)
ORDER BY p.p_partkey;
