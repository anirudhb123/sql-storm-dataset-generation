
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_orderdate DESC) AS rank_order
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierSales AS (
    SELECT 
        s.s_suppkey,
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
        s.s_acctbal > 1000
    GROUP BY 
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_sales,
        ss.order_count
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_sales > (SELECT AVG(total_sales) FROM SupplierSales)
),
FinalReport AS (
    SELECT 
        ro.o_orderkey,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.o_orderpriority,
        COALESCE(hs.s_name, 'No Supplier') AS supplier_name,
        hs.total_sales
    FROM 
        RankedOrders ro
    LEFT JOIN 
        HighValueSuppliers hs ON ro.o_orderkey = (
            SELECT l.l_orderkey
            FROM lineitem l 
            WHERE l.l_orderkey = ro.o_orderkey
            ORDER BY l.l_extendedprice DESC
            LIMIT 1
        )
    WHERE 
        ro.rank_order <= 5
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_orderpriority,
    f.total_sales,
    CASE 
        WHEN f.total_sales IS NULL THEN 'Supplier Not Found'
        ELSE 'Supplier Found'
    END AS supplier_status
FROM 
    FinalReport f
WHERE 
    f.total_sales IS NOT NULL OR f.supplier_name = 'No Supplier'
ORDER BY 
    f.o_orderdate DESC, f.o_orderpriority;
