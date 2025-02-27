WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
), SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey
    FROM 
        SupplierParts sp
    WHERE 
        sp.total_supply_cost > (
            SELECT 
                AVG(total_supply_cost) 
            FROM 
                SupplierParts
        )
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(o.total_revenue) AS average_revenue
FROM 
    RankedOrders o
LEFT JOIN 
    customer c ON o.o_customerkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    HighValueSuppliers hvs ON c.c_nationkey IN (
        SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = c.c_nationkey 
        AND hvs.s_suppkey = ANY (
            SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (
                SELECT p.p_partkey FROM part p WHERE p.p_brand = 'BrandX'
            )
        )
    )
WHERE 
    o.rank_revenue <= 10
GROUP BY 
    r.r_name
ORDER BY 
    total_orders DESC;
