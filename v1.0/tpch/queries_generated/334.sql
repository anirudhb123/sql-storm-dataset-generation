WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100)
),
SupplierCosts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
HighDemandOrders AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_quantity) > 500
)
SELECT r.n_name, COUNT(DISTINCT c.c_custkey) AS customer_count,
       AVG(s.s_acctbal) AS average_account_balance, 
       SUM(COALESCE(sp.total_supply_cost, 0)) AS total_cost,
       STRING_AGG(DISTINCT p.p_name, ', ') AS top_parts
FROM nation r
LEFT JOIN supplier s ON r.n_nationkey = s.s_nationkey
LEFT JOIN customer c ON s.s_suppkey = c.c_nationkey
LEFT JOIN RankedParts p ON s.s_suppkey = p.p_partkey
LEFT JOIN SupplierCosts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN HighDemandOrders h ON h.o_orderkey = s.s_suppkey 
WHERE r.r_name LIKE 'N%' 
GROUP BY r.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY average_account_balance DESC;
