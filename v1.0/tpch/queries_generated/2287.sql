WITH RankedSuppliers AS (
    SELECT s_suppkey, s_name, s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rn
    FROM supplier
),
NationSummary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_balance
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 1000
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, s.s_suppkey, ps.ps_supplycost,
           (ps.ps_supplycost * l.l_quantity) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON l.l_partkey = p.p_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT n.n_name, COUNT(DISTINCT ps.s_suppkey) AS unique_suppliers,
       SUM(ps.total_cost) AS total_part_cost, 
       c.c_name, c.customer_rank
FROM NationSummary n
LEFT JOIN RankedSuppliers ps ON ps.rn = 1
LEFT JOIN TopCustomers c ON c.c_nationkey = n.n_regionkey
LEFT JOIN PartSupplier p ON p.p_partkey IN (
    SELECT p_partkey FROM part WHERE p_size > 10
)
GROUP BY n.n_name, c.c_name, c.customer_rank
HAVING SUM(ps.total_part_cost) IS NOT NULL AND 
       COUNT(DISTINCT ps.s_suppkey) > 0
ORDER BY n.n_name, total_part_cost DESC;
