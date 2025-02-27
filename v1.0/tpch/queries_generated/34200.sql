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
    JOIN SupplyChain sc ON sc.p_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0 AND s.s_suppkey <> sc.s_suppkey
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT DISTINCT c.c_name AS customer_name, 
       s.s_name AS supplier_name, 
       sc.p_name AS part_name, 
       sc.ps_availqty AS available_quantity,
       COALESCE(r.total_spent, 0) AS total_spent,
       CASE WHEN r.rank <= 5 THEN 'Top Customer' ELSE 'Regular Customer' END AS customer_status
FROM SupplyChain sc
LEFT JOIN RankedCustomers r ON r.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = sc.s_nationkey LIMIT 1)
JOIN HighValueSuppliers s ON s.s_name = sc.s_name
WHERE sc.ps_availqty IS NOT NULL
ORDER BY available_quantity DESC, total_spent DESC;
