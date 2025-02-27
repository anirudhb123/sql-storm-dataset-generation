WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_region
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
RegionNations AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        n.n_nationkey,
        n.n_name,
        n.n_comment
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
)
SELECT 
    rn.r_name,
    rn.n_name,
    ss.s_name,
    COALESCE(ss.total_avail_qty, 0) AS total_avail_qty,
    COALESCE(ss.total_supply_value, 0) AS total_supply_value,
    COUNT(co.o_orderkey) AS total_orders,
    AVG(co.o_totalprice) AS avg_order_value
FROM 
    RegionNations rn
LEFT JOIN 
    SupplierStats ss ON ss.s_nationkey = rn.n_nationkey AND ss.rank_in_region <= 5
LEFT JOIN 
    CustomerOrders co ON co.o_orderkey IS NOT NULL
GROUP BY 
    rn.r_name, rn.n_name, ss.s_name
HAVING 
    COUNT(co.o_orderkey) > 10
ORDER BY 
    total_supply_value DESC, rn.r_name, rn.n_name;
