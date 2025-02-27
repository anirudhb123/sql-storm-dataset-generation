WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        RANK() OVER (ORDER BY ss.total_sales DESC) AS rank_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
)
SELECT 
    ns.n_name AS nation_name,
    rs.rank_sales,
    COALESCE(ss.total_sales, 0) AS total_sales,
    CASE 
        WHEN ss.order_count IS NULL THEN 'No Orders'
        ELSE CONCAT(ss.order_count, ' Orders')
    END AS order_summary
FROM 
    nation ns
LEFT OUTER JOIN 
    TopSuppliers rs ON ns.n_nationkey = (SELECT n.n_nationkey FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE s.s_suppkey = rs.s_suppkey)
LEFT JOIN 
    SupplierSales ss ON ss.s_suppkey = rs.s_suppkey
WHERE 
    ns.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Asia%')
ORDER BY 
    rs.rank_sales, ns.n_name;
