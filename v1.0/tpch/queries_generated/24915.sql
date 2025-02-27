WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) as rank_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
    GROUP BY c.c_custkey
),
SelectedNations AS (
    SELECT n.n_nationkey, n.n_name
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'S%')
),
OutsideThreshold AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty * ps.ps_supplycost) > (
        SELECT AVG(total_supply) FROM (
            SELECT SUM(ps1.ps_availqty * ps1.ps_supplycost) AS total_supply
            FROM partsupp ps1
            GROUP BY ps1.ps_partkey
        ) AS AverageSupplies
    )
)
SELECT 
    p.p_name,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(c.order_count, 0) AS order_count,
    s.s_name AS supplier_name,
    ss.total_supply_cost
FROM part p
LEFT JOIN OutsideThreshold ss ON p.p_partkey = ss.ps_partkey
LEFT JOIN RankedSuppliers s ON s.rank_acctbal = 1 AND ss.ps_partkey IS NOT NULL
LEFT JOIN CustomerOrderStats c ON c.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_partkey = p.p_partkey
    ORDER BY o.o_totalprice DESC
    LIMIT 1
)
WHERE p.p_size >= 10
AND (p.p_retailprice IS NULL OR p.p_retailprice > 100.00)
ORDER BY total_spent DESC, p.p_name
LIMIT 50;
