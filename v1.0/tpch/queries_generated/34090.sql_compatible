
WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        SalesCTE s
    JOIN 
        orders o ON s.o_orderkey = o.o_orderkey 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        s.total_sales < (SELECT AVG(total_sales) FROM SalesCTE)
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierSales AS (
    SELECT 
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_total
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_name
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(l.l_extendedprice) AS nation_total
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_name
)
SELECT
    COALESCE(ns.n_name, 'Unknown') AS nation,
    ss.s_name AS supplier,
    COALESCE(ss.supplier_total, 0) AS total_sales_by_supplier,
    COALESCE(ns.nation_total, 0) AS total_sales_by_nation,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(ns.n_name, 'Unknown') ORDER BY COALESCE(ss.supplier_total, 0) DESC) AS rank
FROM 
    SupplierSales ss
FULL OUTER JOIN 
    NationSales ns ON ss.supplier_total = ns.nation_total
ORDER BY 
    nation, supplier;
