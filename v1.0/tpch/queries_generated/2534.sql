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
        o.o_orderstatus = 'O'
        AND l.l_shipdate >= DATE '2023-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionStats AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    rs.r_name,
    ss.s_name,
    ss.total_sales,
    rs.customer_count,
    rs.order_count,
    RANK() OVER (PARTITION BY rs.r_name ORDER BY ss.total_sales DESC) AS supplier_rank
FROM 
    SupplierSales ss
JOIN 
    RegionStats rs ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN supplier s ON ps.ps_suppkey = s.s_suppkey WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n JOIN region r ON n.n_regionkey = r.r_regionkey WHERE r.r_name = rs.r_name))
ORDER BY 
    rs.r_name, supplier_rank;
