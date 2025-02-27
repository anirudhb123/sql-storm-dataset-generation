WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
),
high_value_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
top_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(o.total_revenue) AS nation_revenue
    FROM 
        nation n 
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        order_summary o ON c.c_custkey = o.o_orderkey 
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        nation_revenue DESC
    LIMIT 5
)
SELECT 
    ts.n_name AS nation_name,
    COUNT(DISTINCT rs.s_suppkey) AS num_suppliers,
    SUM(hp.total_supply_cost) AS total_part_supply_cost
FROM 
    top_nations ts
LEFT JOIN 
    ranked_suppliers rs ON ts.n_nationkey = rs.s_nationkey AND rs.rn <= 3
LEFT JOIN 
    high_value_parts hp ON hp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
GROUP BY 
    ts.n_name
ORDER BY 
    num_suppliers DESC, total_part_supply_cost DESC;
