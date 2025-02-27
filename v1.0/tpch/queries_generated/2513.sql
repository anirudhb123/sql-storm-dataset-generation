WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        RANK() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    sr.s_name,
    sr.nation_name,
    sr.region_name,
    SS.total_sales AS supplier_sales,
    COALESCE(AVG(HVO.o_totalprice), 0) AS avg_high_value_order
FROM 
    SupplierRegion sr
LEFT JOIN 
    SupplierSales SS ON sr.s_suppkey = SS.s_suppkey
LEFT JOIN 
    HighValueOrders HVO ON HVO.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_suppkey = sr.s_suppkey
    )
GROUP BY 
    sr.s_name, sr.nation_name, sr.region_name
ORDER BY 
    supplier_sales DESC, sr.s_name;
