WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        ns.n_name AS nation_name,
        rs.s_name AS supplier_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN nation ns ON rs.s_suppkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.rnk <= 3
),
OrderCount AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2022-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ts.region_name,
    ts.nation_name,
    ts.supplier_name,
    osc.order_count,
    lis.total_sales,
    lis.total_quantity
FROM 
    TopSuppliers ts
JOIN 
    OrderCount osc ON ts.s_supplier_key = osc.c_custkey
LEFT JOIN 
    LineItemStats lis ON ts.s_supplier_key = lis.l_orderkey
WHERE 
    ts.s_acctbal IS NOT NULL
ORDER BY 
    ts.region_name, 
    ts.nation_name, 
    ts.total_sales DESC
LIMIT 100;
