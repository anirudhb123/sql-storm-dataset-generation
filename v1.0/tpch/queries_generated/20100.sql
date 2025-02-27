WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey,
           c_name,
           c_acctbal,
           c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c_nationkey ORDER BY c_acctbal DESC) as rn
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer) -- Only customers above average balance
),
PartSupplierCTE AS (
    SELECT ps.partkey,
           s.s_name,
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY ps.ps_partkey, s.s_name
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey 
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 -- High value orders
),
RegionNation AS (
    SELECT r.r_name,
           n.n_name,
           COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY r.r_name, n.n_name
)
SELECT c.c_name,
       coalesce(par.part_name, 'No Parts') AS Part_Name,
       c.c_acctbal AS Customer_Balance,
       r.r_name AS Region,
       AVG(c.cte_rn) OVER (PARTITION BY r.r_name) AS Avg_Customer_Rank,
       ps.total_supply_cost,
       o.total_order_value
FROM CustomerCTE c
LEFT JOIN PartSupplierCTE ps ON ps.partkey = (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_supplycost = (SELECT MAX(ps_supplycost) FROM partsupp)
)
LEFT JOIN HighValueOrders o ON o.o_orderkey = (
    SELECT MIN(o_orderkey)
    FROM HighValueOrders
    WHERE total_order_value = o.total_order_value
)
LEFT JOIN (
    SELECT DISTINCT p.p_partkey, p.p_name AS part_name
    FROM part p
    WHERE p.p_size IN (SELECT p_size FROM part WHERE p_retailprice < 50.00)
) par ON par.p_partkey = ps.partkey
JOIN RegionNation r ON r.customer_count > 5
WHERE c.rn <= 10
ORDER BY Customer_Balance DESC, Region;
