WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighSpenders AS (
    SELECT c.c_custkey, c.total_spent
    FROM CustomerOrders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
PartDetails AS (
    SELECT p.p_partkey,
           p.p_name,
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT h.c_custkey,
       h.total_spent,
       p.p_partkey,
       p.p_name,
       COALESCE(r.s_name, 'No Supplier') AS supplier_name,
       p.total_quantity,
       CASE 
           WHEN r.rank = 1 THEN 'Best Supplier'
           ELSE 'Other Supplier'
       END AS supplier_status
FROM HighSpenders h
LEFT JOIN PartDetails p ON p.total_quantity > 0
LEFT JOIN RankedSuppliers r ON r.rank = 1 AND p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
ORDER BY h.total_spent DESC, p.p_name ASC;
