WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
TopSuppliers AS (
    SELECT 
        t.s_suppkey, 
        t.s_name, 
        t.s_acctbal
    FROM 
        RankedSupplier t
    WHERE 
        t.rank <= 3
), 
OrderDetail AS (
    SELECT 
        o.o_orderkey, 
        l.l_partkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        l.l_tax, 
        CASE 
            WHEN l.l_returnflag = 'R' THEN 'Returned' 
            ELSE 'Not Returned' 
        END AS return_status
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
), 
AggregatedSales AS (
    SELECT 
        p.p_partkey,
        SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
        ROUND(AVG(od.l_tax), 2) AS avg_tax
    FROM 
        part p
    LEFT JOIN 
        OrderDetail od ON p.p_partkey = od.l_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    s.s_name, 
    r.r_name, 
    ps.ps_partkey, 
    ns.total_sales,
    ns.avg_tax,
    COALESCE(NULLIF(ns.total_sales, 0), MAX(ns.avg_tax)) AS sales_or_avg_tax, 
    COUNT(DISTINCT CASE WHEN od.return_status = 'Returned' THEN od.l_orderkey END) AS returned_orders_count
FROM 
    TopSuppliers s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'O')))))
LEFT JOIN 
    AggregatedSales ns ON ps.ps_partkey = ns.p_partkey
LEFT JOIN 
    OrderDetail od ON od.l_partkey = ps.ps_partkey
WHERE 
    ns.total_sales > 10000 
    AND (s.s_acctbal IS NOT NULL OR s.s_name IS NOT NULL)
GROUP BY 
    s.s_name, r.r_name, ps.ps_partkey, ns.total_sales, ns.avg_tax
HAVING 
    SUM(od.l_quantity) > 100
ORDER BY 
    ns.total_sales DESC, s.s_name;
