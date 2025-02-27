WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE ps.ps_availqty > 0 AND sc.ps_supplycost < ps.ps_supplycost
), 

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 

RankedCustomers AS (
    SELECT c.*, RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders c
), 

PartSupplierCosts AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)

SELECT rc.c_name, rc.order_count, rc.total_spent, 
       pc.p_name, pc.total_supply_cost, 
       CASE 
           WHEN rc.total_spent IS NULL THEN 'No Orders' 
           ELSE 'Has Orders' 
       END AS order_status,
       COALESCE(SUM(sc.ps_availqty), 0) AS available_quantity
FROM RankedCustomers rc
LEFT JOIN PartSupplierCosts pc ON rc.c_custkey = pc.p_partkey
LEFT JOIN SupplyChain sc ON pc.p_partkey = sc.p_partkey
GROUP BY rc.c_name, rc.order_count, rc.total_spent, pc.p_name, pc.total_supply_cost
HAVING rc.rank <= 5 AND total_supply_cost IS NOT NULL
ORDER BY rc.total_spent DESC;
