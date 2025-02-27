WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
supplier_parts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 500
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT tc.c_custkey) AS num_top_customers,
    SUM(sp.total_quantity) AS total_supplier_parts,
    AVG(sp.avg_supply_cost) AS avg_supplier_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    supplier_parts sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    top_customers tc ON tc.customer_total > 100000
GROUP BY 
    r.r_name
ORDER BY 
    total_supplier_parts DESC, num_top_customers DESC;
