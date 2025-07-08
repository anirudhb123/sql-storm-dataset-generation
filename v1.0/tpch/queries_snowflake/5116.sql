WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
), TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name 
    FROM 
        SupplierSales s
    ORDER BY 
        s.total_revenue DESC 
    LIMIT 10
), OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ts.s_name AS supplier_name,
    os.o_orderkey,
    os.o_orderdate,
    os.order_total
FROM 
    TopSuppliers ts
JOIN 
    OrderSummary os ON ts.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE 
            l.l_orderkey = os.o_orderkey 
        LIMIT 1
    )
ORDER BY 
    os.order_total DESC, ts.s_name ASC;