WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
TopOrders AS (
    SELECT 
        oh.o_orderkey,
        oh.o_orderstatus,
        oh.total_revenue,
        COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returns
    FROM 
        OrderHierarchy oh
    LEFT JOIN 
        lineitem l ON oh.o_orderkey = l.l_orderkey
    WHERE 
        oh.rn = 1
    GROUP BY 
        oh.o_orderkey, oh.o_orderstatus, oh.total_revenue
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
)
SELECT 
    to.o_orderkey,
    to.o_orderstatus,
    to.total_revenue,
    sr.supplier_revenue,
    CASE 
        WHEN sr.supplier_revenue IS NULL THEN 'No Revenue'
        ELSE 'Revenue Present'
    END AS revenue_status
FROM 
    TopOrders to
LEFT JOIN 
    SupplierRevenue sr ON to.o_orderkey = sr.ps_suppkey
WHERE 
    to.total_revenue > 50000
ORDER BY 
    to.total_revenue DESC
LIMIT 10;
