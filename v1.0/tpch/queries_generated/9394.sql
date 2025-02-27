WITH ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_type
),
top_suppliers AS (
    SELECT 
        p.p_type,
        rs.s_suppkey,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        ranked_suppliers rs
    JOIN 
        part p ON p.p_type = p.p_type
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    r.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS num_customers,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_discount) AS avg_discount,
    COUNT(DISTINCT ts.s_suppkey) AS num_top_suppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    top_suppliers ts ON ts.s_suppkey = s.s_suppkey
GROUP BY 
    r.r_name, n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
