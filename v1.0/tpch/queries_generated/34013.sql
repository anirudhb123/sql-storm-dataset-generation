WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
    UNION ALL
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F' 
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, s.s_name, 
           (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(SUM(l.l_quantity), 0) AS total_quantity_sold
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(l.l_quantity) IS NOT NULL
)
SELECT c.c_name, cp.total_spent, p.p_name, p.p_retailprice, 
       psd.total_cost, r.r_name AS region_name
FROM CustomerOrders cp
JOIN FilteredParts p ON cp.total_spent > (0.2 * (
    SELECT AVG(total_spent) FROM CustomerOrders WHERE total_spent IS NOT NULL))
LEFT JOIN PartSupplierDetails psd ON p.p_partkey = psd.p_partkey AND psd.rank = 1
LEFT JOIN supplier s ON psd.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name IS NOT NULL
ORDER BY cp.total_spent DESC, p.p_retailprice ASC;
