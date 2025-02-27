WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 100
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
), TopCustomers AS (
    SELECT c.c_custkey, c.c_name, total_spent,
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders c
), HighestRankedSuppliers AS (
    SELECT s.s_name, p.p_name, p.p_retailprice, sc.ps_availqty, sc.ps_supplycost
    FROM SupplyChain sc
    JOIN part p ON sc.ps_partkey = p.p_partkey
    WHERE sc.supplier_rank = 1
)
SELECT DISTINCT c.c_name, c.total_spent, s.s_name, p.p_name, 
       COALESCE(s.ps_availqty, 0) AS available_quantity, 
       s.ps_supplycost * 1.05 AS adjusted_supply_cost
FROM TopCustomers c
LEFT JOIN HighestRankedSuppliers s ON c.c_custkey = s.ps_partkey
WHERE c.rank <= 10 AND (c.total_spent > 10000 OR s.ps_supplycost IS NOT NULL)
ORDER BY c.total_spent DESC, s.s_name ASC;
