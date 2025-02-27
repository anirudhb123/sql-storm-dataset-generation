WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL

    SELECT s2.s_suppkey, s2.s_name, s2.s_nationkey, s2.s_acctbal, sh.level + 1
    FROM supplier s2
    JOIN SupplierHierarchy sh ON s2.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopCustomers AS (
    SELECT c_custkey, c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c_custkey, c_name
    ORDER BY total_spent DESC
    LIMIT 10
),
PartSupplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS price_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > 50.00
),
FinalResults AS (
    SELECT 
        n.n_name AS nation_name,
        sh.s_name AS supplier_name,
        tc.c_name AS customer_name,
        ps.p_name AS part_name,
        ps.ps_supplycost AS supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM SupplierHierarchy sh
    JOIN nation n ON sh.s_nationkey = n.n_nationkey
    JOIN lineitem li ON sh.s_suppkey = li.l_suppkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    JOIN TopCustomers tc ON o.o_custkey = tc.c_custkey
    JOIN PartSupplier ps ON li.l_partkey = ps.p_partkey AND ps.price_rank = 1
    GROUP BY n.n_name, sh.s_name, tc.c_name, ps.p_name, ps.ps_supplycost
    HAVING COUNT(DISTINCT o.o_orderkey) > 5
)
SELECT *
FROM FinalResults
WHERE supplier_name IS NOT NULL
ORDER BY nation_name, supplier_name, customer_name;
