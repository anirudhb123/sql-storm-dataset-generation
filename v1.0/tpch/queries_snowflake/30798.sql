
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS depth
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), OrderSummary AS (
    SELECT 
        o.o_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_mktsegment = 'BUILDING'
    GROUP BY o.o_custkey
), PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(os.total_orders) AS collective_order_count,
    SUM(os.total_revenue) AS collective_revenue,
    LISTAGG(DISTINCT CONCAT(p.p_name, ' - ', p.total_available), '; ') WITHIN GROUP (ORDER BY p.p_name) AS available_parts,
    MAX(p.avg_supply_cost) AS max_avg_supply_cost,
    COUNT(DISTINCT sh.s_suppkey) AS distinct_high_balance_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderSummary os ON os.o_custkey = c.c_custkey
LEFT JOIN PartSupplier p ON p.p_partkey = (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) 
        FROM partsupp ps2
    )
    LIMIT 1
)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE r.r_name LIKE 'S%' AND n.n_comment IS NOT NULL
GROUP BY r.r_name, n.n_name
ORDER BY collective_revenue DESC;
