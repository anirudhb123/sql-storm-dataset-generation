WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O'
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, s.s_name, sd.total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    JOIN supplier s ON p.p_partkey = s.s_nationkey
    JOIN SupplierCost sd ON p.p_partkey = sd.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_container IS NULL)
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey
),
FinalSummary AS (
    SELECT pd.p_name, pd.p_brand, co.total_spent,
           CASE 
               WHEN co.total_spent IS NULL THEN 'No Orders'
               WHEN co.total_spent >= 1000 THEN 'High Roller'
               ELSE 'Regular Customer'
           END AS customer_status
    FROM PartDetails pd
    LEFT JOIN CustomerOrders co ON pd.p_partkey = co.c_custkey
)
SELECT f.p_name, f.p_brand, f.total_spent, f.customer_status
FROM FinalSummary f
WHERE f.customer_status != 'No Orders'
ORDER BY f.total_spent DESC
LIMIT 10;
