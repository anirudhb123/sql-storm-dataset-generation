WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        r.r_name AS supplier_region,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), ProductInfo AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    si.s_name AS supplier_name, 
    si.supplier_region, 
    pi.p_name AS product_name, 
    pi.p_retailprice, 
    os.o_orderkey, 
    os.o_orderdate, 
    os.total_revenue, 
    os.total_quantity, 
    CONCAT('Order Date: ', os.o_orderdate, ', Revenue: $', FORMAT(os.total_revenue, 2), ', Quantity: ', os.total_quantity) AS order_details
FROM 
    SupplierInfo si
JOIN 
    ProductInfo pi ON pi.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey = si.s_suppkey
    )
JOIN 
    order_summary os ON os.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = pi.ps_partkey
    )
ORDER BY 
    os.total_revenue DESC, 
    si.s_name, 
    os.o_orderdate;
