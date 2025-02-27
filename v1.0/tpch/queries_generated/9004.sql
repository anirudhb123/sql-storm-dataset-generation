WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
)
SELECT 
    r.r_name AS Region_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    AVG(o.o_totalprice) AS Average_Order_Value,
    COUNT(DISTINCT ts.s_suppkey) AS Unique_Suppliers,
    SUM(ts.total_supply_cost) AS Total_Supply_Cost
FROM 
    HighValueRegions r
JOIN 
    RankedOrders o ON o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
JOIN 
    TopSuppliers ts ON ts.total_supply_cost > 500000
GROUP BY 
    r.r_name
ORDER BY 
    Total_Orders DESC, Average_Order_Value DESC;
