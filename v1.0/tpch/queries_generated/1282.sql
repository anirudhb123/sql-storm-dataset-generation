WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS total_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
) 
SELECT 
    ns.n_name AS nation_name,
    COUNT(DISTINCT cs.c_custkey) AS num_customers,
    SUM(cs.total_spent) AS total_revenue,
    AVG(ss.total_supply_cost) AS avg_supply_cost_per_supplier,
    STRING_AGG(DISTINCT p.p_comment) AS distinct_part_comments,
    MAX(COALESCE(ss.total_parts, 0)) AS max_parts_per_supplier
FROM nation ns
LEFT JOIN supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN CustomerOrders cs ON s.s_nationkey = cs.c_custkey
INNER JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
WHERE ns.n_name IS NOT NULL AND ss.total_supply_cost > 0
GROUP BY ns.n_name
HAVING COUNT(DISTINCT cs.c_custkey) > 0
ORDER BY total_revenue DESC, num_customers ASC;
