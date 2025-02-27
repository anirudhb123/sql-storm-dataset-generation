WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2020-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
),
HighSpendingCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(co.net_spent) AS total_spent
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(co.net_spent) > 100000
),
TopPartSuppliers AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           p.p_name, s.s_name, 
           CASE 
               WHEN ps.ps_availqty IS NULL THEN 'Out of Stock' 
               ELSE 'In Stock' 
           END AS stock_status
    FROM partsupp ps
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey 
    WHERE rs.supplier_rank = 1
)
SELECT tps.p_name, tps.s_name, hsc.total_spent,
       CASE 
           WHEN hsc.total_spent IS NULL THEN 'No Purchases Yet! '
           ELSE CONCAT('Total Spent: ', hsc.total_spent)
       END AS customer_status,
       COALESCE(tps.stock_status, 'Unknown') AS availability_status
FROM TopPartSuppliers tps
FULL OUTER JOIN HighSpendingCustomers hsc ON tps.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_suppkey = tps.ps_suppkey FETCH FIRST 1 ROW ONLY)
WHERE (tps.ps_availqty >= 50 OR hsc.total_spent IS NULL)
ORDER BY tps.p_name ASC, hsc.total_spent DESC;
