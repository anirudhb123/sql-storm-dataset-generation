WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        l.l_quantity,
        l.l_extendedprice,
        CASE
            WHEN l.l_discount > 0.05 THEN 'High Discount'
            ELSE 'Standard Discount'
        END AS discount_category
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
),
AggregatedOrders AS (
    SELECT
        od.discount_category,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
        COUNT(od.o_orderkey) AS order_count
    FROM 
        OrderDetails od
    GROUP BY 
        od.discount_category
),
FinalResults AS (
    SELECT 
        ps.p_partkey,
        ps.p_name,
        COALESCE(SUM(o.total_sales), 0) AS total_sales,
        COALESCE(SUM(o.order_count), 0) AS total_orders,
        rs.s_name AS top_supplier_name
    FROM 
        PartSupplierDetails ps
    LEFT JOIN 
        AggregatedOrders o ON ps.p_partkey = o.discount_category  -- An unconventional join for demonstration
    LEFT JOIN 
        RankedSuppliers rs ON ps.s_suppkey = rs.s_suppkey AND rs.rank = 1
    GROUP BY 
        ps.p_partkey, ps.p_name, rs.s_name
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.total_sales,
    f.total_orders,
    f.top_supplier_name
FROM 
    FinalResults f
WHERE 
    f.total_sales > 1000
ORDER BY 
    f.total_sales DESC;
