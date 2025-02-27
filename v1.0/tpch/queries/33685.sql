
WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_availqty - 10 AS ps_availqty, ps.ps_supplycost, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE ps.ps_availqty > 0 AND ps.ps_availqty > sc.ps_availqty 
), FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 500
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost,
           RANK() OVER (ORDER BY AVG(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.p_name, r.avg_supply_cost, c.c_name, c.total_spent
FROM RankedParts r
LEFT JOIN FilteredCustomers c ON r.p_partkey = (
    SELECT MAX(ps.ps_partkey) FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_name LIKE '%Supplier%' AND ps.ps_availqty > 5
)
WHERE r.rank <= 5
ORDER BY r.avg_supply_cost DESC, c.total_spent ASC
LIMIT 10;
