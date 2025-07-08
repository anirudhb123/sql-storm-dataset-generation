
WITH RECURSIVE YearlySales (order_year, total_sales) AS (
    SELECT 
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        EXTRACT(YEAR FROM o.o_orderdate)
    UNION ALL
    SELECT 
        ys.order_year + 1,
        SUM(l.l_extendedprice * (1 - l.l_discount))
    FROM 
        YearlySales ys
    JOIN 
        orders o ON EXTRACT(YEAR FROM o.o_orderdate) = ys.order_year + 1
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        ys.order_year + 1
),
SupplierWithAvgCost AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        s.s_acctbal,
        swac.avg_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierWithAvgCost swac ON s.s_suppkey = swac.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    ORDER BY 
        swac.avg_supply_cost DESC
    LIMIT 10
)
SELECT 
    ys.order_year,
    SUM(t.total_sales) AS total_sales,
    COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name,
    ts.s_acctbal,
    CASE 
        WHEN COUNT(ts.s_suppkey) > 0 THEN 'Exists'
        ELSE 'Does Not Exist'
    END AS supplier_status
FROM 
    YearlySales ys
LEFT JOIN 
    (
        SELECT 
            EXTRACT(YEAR FROM o.o_orderdate) AS year,
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
            l.l_suppkey
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY 
            EXTRACT(YEAR FROM o.o_orderdate), l.l_suppkey
    ) t ON t.year = ys.order_year
LEFT JOIN 
    TopSuppliers ts ON t.l_suppkey = ts.s_suppkey
GROUP BY 
    ys.order_year, ts.s_name, ts.s_acctbal
ORDER BY 
    ys.order_year;
