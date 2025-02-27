WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
    UNION ALL
    SELECT co.c_custkey, co.c_name, co.total_spent + SUM(o.o_totalprice)
    FROM CustomerOrders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    GROUP BY co.c_custkey, co.c_name, co.total_spent
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
TopSuppliers AS (
    SELECT p.p_partkey, p.p_name, ps.s_suppkey, ps.ps_supplycost, ps.ps_availqty, 
           s.s_name, s.s_nationkey, 
           CASE 
               WHEN ps.ps_supplycost > 20 THEN 'High Cost' 
               ELSE 'Low Cost' 
           END AS cost_category
    FROM PartSuppliers ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.p_partkey = p.p_partkey
    WHERE ps.rn = 1
),
CustomerSummary AS (
    SELECT co.c_custkey, co.c_name, co.total_spent, 
           RANK() OVER (ORDER BY co.total_spent DESC) AS cust_rank,
           ROW_NUMBER() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS order_rank
    FROM CustomerOrders co
)
SELECT cs.c_name, cs.total_spent, ts.p_name, ts.cost_category, 
       CASE 
           WHEN ts.ps_availqty IS NULL THEN 'No Supplier'
           ELSE 'Available'
       END AS availability
FROM CustomerSummary cs
LEFT JOIN TopSuppliers ts ON cs.c_custkey = ts.ps_suppkey
WHERE cs.cust_rank <= 10
ORDER BY cs.total_spent DESC, ts.cost_category DESC;
