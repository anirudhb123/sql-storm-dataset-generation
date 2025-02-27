WITH RECURSIVE AvgSupplierCost AS (
    SELECT ps_partkey, AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_partkey
),
RecentOrders AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_spent
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'
    GROUP BY o_custkey
),
HighSpenderCustomers AS (
    SELECT c.c_custkey, c.c_name, RANK() OVER (ORDER BY ro.total_spent DESC) AS spender_rank
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    WHERE ro.total_spent > 1000
),
SupplierAndPart AS (
    SELECT s.s_name, p.p_name, p.p_brand, p.p_retailprice, ASC.avg_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN AvgSupplierCost ASC ON p.p_partkey = ASC.ps_partkey
)
SELECT 
    hsc.c_name,
    sp.s_name,
    sp.p_name,
    sp.p_brand,
    sp.p_retailprice,
    COALESCE(ASC.avg_cost, 0) AS avg_supply_cost,
    CASE 
        WHEN sp.p_retailprice IS NULL THEN 'Price Unknown'
        WHEN sp.p_retailprice > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS price_category
FROM HighSpenderCustomers hsc
FULL OUTER JOIN SupplierAndPart sp ON hsc.c_custkey = sp.s_suppkey
WHERE (sp.p_retailprice IS NOT NULL AND sp.p_retailprice <> 0)
ORDER BY hsc.spender_rank ASC, sp.p_brand ASC;
