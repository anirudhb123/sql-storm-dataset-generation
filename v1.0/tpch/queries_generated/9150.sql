WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
supply_summary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name,
    SUM(o.order_value) AS total_order_value,
    SUM(ss.unique_parts) AS total_unique_parts_supplied,
    AVG(ss.total_supply_cost) AS avg_supply_cost_per_supplier
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    supply_summary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    ranked_orders o ON o.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = n.n_nationkey))
GROUP BY 
    r.r_name
ORDER BY 
    total_order_value DESC, 
    total_unique_parts_supplied DESC
LIMIT 10;
