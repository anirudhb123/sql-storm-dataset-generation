WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000.00
),
LowQuantityOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) as total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_quantity) < 100
),
HighPriceParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SupplierOrders AS (
    SELECT 
        o.o_orderkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name
    FROM 
        lineitem l
    LEFT JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
)
SELECT 
    r.region_name,
    p.p_name,
    COUNT(DISTINCT so.o_orderkey) AS order_count,
    AVG(so.l_extendedprice - (so.l_extendedprice * so.l_discount)) AS avg_discounted_price,
    SUM(CASE WHEN so.l_quantity > 10 THEN so.l_quantity ELSE NULL END) AS high_quantity_sum,
    COUNT(DISTINCT CASE WHEN ls.total_quantity IS NOT NULL THEN ls.o_orderkey END) AS low_quantity_order_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rs ON n.n_nationkey = rs.s_suppkey
LEFT JOIN 
    SupplierOrders so ON so.supplier_name = rs.s_name
LEFT JOIN 
    HighPriceParts p ON so.l_partkey = p.p_partkey
LEFT JOIN 
    LowQuantityOrders ls ON so.o_orderkey = ls.o_orderkey
WHERE 
    rs.rank <= 5
GROUP BY 
    r.region_name, p.p_name
ORDER BY 
    r.region_name, order_count DESC;
