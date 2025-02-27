WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING SUM(o.o_totalprice) > 10000
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           COUNT(*) AS total_lines, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
           AVG(l.l_quantity) AS avg_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           COALESCE(rn_ranks.s_name, 'Unknown') AS supplier_name, 
           COALESCE(rn_ranks.s_acctbal, 0) AS supplier_acctbal
    FROM part p
    LEFT JOIN RankedSuppliers rn_ranks ON p.p_partkey = rn_ranks.s_suppkey AND rn_ranks.rn = 1
)
SELECT hvc.c_name, hvc.total_spent, sp.p_name, sp.supplier_name, 
       l.total_lines, l.total_value, l.avg_quantity
FROM HighValueCustomers hvc
JOIN orders o ON hvc.c_custkey = o.o_custkey
JOIN LineItemStats l ON o.o_orderkey = l.l_orderkey
JOIN SupplierPartDetails sp ON sp.p_partkey IN (
   SELECT ps.ps_partkey
   FROM partsupp ps 
   JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
   WHERE s.s_acctbal > 5000
)
WHERE o.o_orderdate >= DATE '2022-01-01' 
  AND o.o_orderdate < DATE '2023-01-01'
ORDER BY hvc.total_spent DESC, l.total_value DESC
LIMIT 100;
