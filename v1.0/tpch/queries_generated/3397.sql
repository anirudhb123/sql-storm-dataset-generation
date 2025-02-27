WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
OrderSummary AS (
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
    HAVING 
        SUM(o.o_totalprice) > 5000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    COALESCE(rs.total_supply_cost, 0) AS highest_cost_supplier,
    os.total_orders,
    os.total_spent
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey AND rs.supplier_rank = 1
LEFT JOIN 
    OrderSummary os ON os.total_orders > 0
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part) 
    OR p.p_container IS NULL
ORDER BY 
    p.p_partkey;
