WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp)
),
SupplierOrderDetails AS (
    SELECT 
        l.l_orderkey,
        s.s_suppkey,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY s.s_name) AS supplier_rank
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
)
SELECT 
    r.o_orderkey,
    MAX(sod.s_supplier_id) AS preferred_supplier,
    CASE 
        WHEN MAX(r.total_revenue) IS NULL THEN 'No Revenue'
        ELSE TO_CHAR(MAX(r.total_revenue), 'FM999,999,999.00')
    END AS formatted_revenue,
    COALESCE(SUM(hvs.total_cost), 0) AS total_supplier_cost
FROM 
    RankedOrders r
LEFT JOIN 
    SupplierOrderDetails sod ON r.o_orderkey = sod.l_orderkey
LEFT JOIN 
    HighValueSuppliers hvs ON sod.s_suppkey = hvs.s_suppkey
WHERE 
    r.revenue_rank <= 3 
GROUP BY 
    r.o_orderkey
ORDER BY 
    r.o_orderkey DESC
FETCH FIRST 10 ROWS ONLY;
