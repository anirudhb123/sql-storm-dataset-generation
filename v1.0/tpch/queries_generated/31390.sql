WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_retailprice, 0 AS level
    FROM part
    WHERE p_retailprice > 100.00
    
    UNION ALL
    
    SELECT ps.ps_partkey, p.p_name, p.p_retailprice, ph.level + 1
    FROM partsupp ps
    JOIN PartHierarchy ph ON ps.ps_partkey = ph.p_partkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_supplycost < 50.00
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT *,
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders
)
SELECT ph.p_name,
       ph.p_retailprice,
       rc.c_name,
       rc.total_spent,
       CASE 
           WHEN rc.total_spent IS NULL THEN 'No Orders'
           ELSE CONCAT('Spent: $', ROUND(rc.total_spent, 2))
       END AS spending_info
FROM PartHierarchy ph
LEFT JOIN RankedCustomers rc ON rc.total_spent > ph.p_retailprice
WHERE ph.level < 3
AND EXISTS (
    SELECT 1 
    FROM lineitem l
    WHERE l.l_partkey = ph.p_partkey AND l.l_returnflag = 'N'
)
ORDER BY ph.p_retailprice DESC, rc.rank ASC;
