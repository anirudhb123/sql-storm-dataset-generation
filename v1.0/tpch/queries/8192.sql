
WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        r.r_name AS region_name,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
order_summary AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(*) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        ranked_orders o
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_orderkey)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.order_rank <= 5
    GROUP BY 
        r.r_name
), 
part_supplier_details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost, 
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    os.region_name,
    os.total_orders,
    os.total_revenue,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_costs
FROM 
    order_summary os
JOIN 
    part_supplier_details p ON os.total_orders > 0
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY 
    os.region_name, os.total_orders, os.total_revenue
ORDER BY 
    os.total_revenue DESC;
