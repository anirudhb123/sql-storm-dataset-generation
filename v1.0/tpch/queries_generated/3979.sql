WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        RANK() OVER (ORDER BY total_supply_value DESC) AS supplier_rank
    FROM 
        SupplierSummary s
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    c.c_name,
    COALESCE(cs.total_sales, 0) AS total_sales,
    COALESCE(s.total_supply_value, 0) AS total_supply_value,
    COUNT(DISTINCT fo.o_orderkey) AS orders_count,
    SUM(fa.net_revenue) AS total_revenue,
    AVG(fa.avg_quantity) AS average_quantity
FROM 
    customer c
LEFT JOIN 
    CustomerSales cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    FilteredOrders fo ON fo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN 
    LineItemAnalysis fa ON fo.o_orderkey = fa.l_orderkey
LEFT JOIN 
    TopSuppliers s ON s.s_suppkey = fa.l_suppkey
GROUP BY 
    c.c_name
ORDER BY 
    total_sales DESC, total_supply_value DESC;
