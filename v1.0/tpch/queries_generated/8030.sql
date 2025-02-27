WITH ranked_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
), suppliers_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
), customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.total_quantity,
    rp.total_revenue,
    si.s_name AS supplier_name,
    si.nation_name,
    si.region_name,
    co.order_count,
    co.total_spent
FROM 
    ranked_parts rp
JOIN 
    suppliers_info si ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_suppkey)
LEFT JOIN 
    customer_orders co ON rp.total_revenue > 1000000
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.total_revenue DESC;
