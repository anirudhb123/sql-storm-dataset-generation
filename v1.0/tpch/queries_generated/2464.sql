WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count, 
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    s.total_supply_cost,
    cos.order_count,
    cos.total_spent,
    CASE 
        WHEN cos.total_spent IS NULL OR cos.total_spent = 0 THEN 'No Spending' 
        WHEN cos.total_spent < 100 THEN 'Low Spending'
        ELSE 'High Spending'
    END AS spending_category
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderStats cos ON s.s_suppkey = cos.c_custkey
WHERE 
    s.rank <= 3
ORDER BY 
    r.r_name, 
    total_supply_cost DESC;
