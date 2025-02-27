WITH RECURSIVE SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
    
    UNION ALL

    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_sales * 1.1 AS total_sales
    FROM 
        SupplierSales ss
    WHERE 
        ss.total_sales < 100000
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    ns.n_name AS nation,
    SUM(fs.total_sales) AS total_supplier_sales,
    COALESCE(SUM(co.order_count), 0) AS total_orders,
    MAX(fo.order_total) AS max_order_total,
    AVG(fo.line_count) AS avg_line_count
FROM 
    nation ns
LEFT JOIN 
    SupplierSales fs ON ns.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE s.s_suppkey = fs.s_suppkey)
LEFT JOIN 
    CustomerOrderStats co ON ns.n_nationkey = (SELECT c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
LEFT JOIN 
    FilteredOrders fo ON co.total_spent > 5000
GROUP BY 
    ns.n_name
HAVING 
    SUM(fs.total_sales) IS NOT NULL
ORDER BY 
    total_supplier_sales DESC;
