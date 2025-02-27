WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionSales AS (
    SELECT 
        r.r_name,
        SUM(ss.supplier_sales) AS region_total
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.region_total,
    COALESCE(s.net_sales, 0) AS total_sales,
    CASE 
        WHEN r.region_total > 0 THEN (COALESCE(s.net_sales, 0) / r.region_total) * 100
        ELSE 0
    END AS sales_percentage
FROM 
    RegionSales r
LEFT OUTER JOIN 
    (SELECT * FROM SalesCTE WHERE order_rank = 1) s ON r.r_name = s.o_orderdate
WHERE 
    r.region_total > 10000
ORDER BY 
    sales_percentage DESC, r.r_name;
