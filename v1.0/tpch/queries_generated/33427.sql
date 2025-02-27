WITH RECURSIVE total_costs AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
filtered_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice - COALESCE(SUM(l.l_discount * l.l_extendedprice), 0) AS adjusted_total
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
top_customers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.adjusted_total) AS total_spent
    FROM 
        customer c
    JOIN 
        filtered_orders o ON c.c_custkey = o.o_orderkey -- Assuming custkey matches orderkey, otherwise adjust
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        total_spent DESC
    LIMIT 10
),
ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        tc.total_spent,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY tc.total_spent DESC) AS rnk
    FROM 
        part p
    LEFT JOIN 
        total_costs tc ON p.p_partkey = tc.ps_partkey
)

SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(tc.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN p.p_size IS NULL THEN 'Size Unknown' 
        ELSE CONCAT('Size ', p.p_size) 
    END AS formatted_size,
    CASE WHEN rp.rnk = 1 THEN 'Top Ranked Part' ELSE 'Regular Part' END AS part_rank_status
FROM 
    part p
LEFT JOIN 
    total_costs tc ON p.p_partkey = tc.ps_partkey
LEFT JOIN 
    ranked_parts rp ON p.p_partkey = rp.p_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_retailprice IS NOT NULL)
ORDER BY 
    total_supply_cost DESC, 
    p.p_name

