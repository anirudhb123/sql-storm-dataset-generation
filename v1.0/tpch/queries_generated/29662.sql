WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_availqty) AS Total_Available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Supplier_Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
TopRegions AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS Nation_Count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
    HAVING 
        COUNT(DISTINCT n.n_nationkey) > 1
),
CustomerInfo AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS Total_Orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    c.c_name AS Customer_Name,
    SUM(i.l_extendedprice * (1 - i.l_discount)) AS Revenue,
    r.r_name AS Region_Name,
    s.s_name AS Supplier_Name,
    rs.Total_Available,
    rs.Total_Cost
FROM 
    lineitem i
JOIN 
    orders o ON i.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON s.s_suppkey = i.l_suppkey
JOIN 
    RankedSuppliers rs ON s.s_name = rs.s_name
JOIN 
    TopRegions r ON r.r_name = (SELECT r2.r_name FROM region r2 JOIN nation n ON r2.r_regionkey = n.n_regionkey WHERE n.n_nationkey = c.c_nationkey)
GROUP BY 
    c.c_name, r.r_name, s.s_name, rs.Total_Available, rs.Total_Cost
HAVING 
    SUM(i.l_extendedprice * (1 - i.l_discount)) > 10000
ORDER BY 
    Revenue DESC;
