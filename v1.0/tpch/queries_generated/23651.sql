WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS Total_Available,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        AVG(o.o_totalprice) AS Avg_Order_Value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        AVG(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue,
        COUNT(DISTINCT l.l_suppkey) AS Distinct_Suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1994-01-01' AND o.o_orderdate < '1995-01-01'
    GROUP BY 
        o.o_orderkey
),
NationsWithSuppliers AS (
    SELECT 
        n.n_name,
        COALESCE(rg.r_total_qty, 0) AS total_supplier_qty
    FROM 
        nation n
    LEFT JOIN (
        SELECT 
            ps.ps_partkey,
            SUM(ps.ps_availqty) AS r_total_qty
        FROM 
            partsupp ps
        GROUP BY 
            ps.ps_partkey
    ) rg ON n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps))
)
SELECT 
    c.c_name,
    COALESCE(rd.Total_Available, 0) AS Total_Available_Supplies,
    o.Revenue,
    o.Distinct_Suppliers,
    n.total_supplier_qty
FROM 
    HighValueCustomers c
LEFT JOIN 
    RankedSuppliers rd ON c.c_custkey = rd.s_suppkey
JOIN 
    OrderDetails o ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = o.o_orderkey)
LEFT JOIN 
    NationsWithSuppliers n ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'Canada')
WHERE 
    n.total_supplier_qty IS NOT NULL
    AND o.Revenue > 10000
    AND (rd.rank = 1 OR rd.rank IS NULL)
ORDER BY 
    c.c_name ASC, o.Revenue DESC;
