WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    region.r_name,
    COALESCE(cs.total_orders, 0) AS customer_orders,
    COALESCE(cs.total_spent, 0) AS customer_spent,
    rs.total_supply_value,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey
LEFT JOIN 
    nation n ON rs.nation_name = n.n_name
LEFT JOIN 
    region ON n.n_regionkey = region.r_regionkey
LEFT JOIN 
    CustomerOrderStats cs ON cs.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_name LIKE '%Customer%'
    )
WHERE 
    p.p_size > 15 AND 
    (p.p_brand LIKE 'Brand%' OR p.p_mfgr LIKE 'Manufacturer%')
GROUP BY 
    p.p_name, region.r_name, cs.total_orders, cs.total_spent, rs.total_supply_value
ORDER BY 
    avg_price_after_discount DESC;
