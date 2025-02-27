
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierRevenue AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    WHERE 
        l.l_shipdate BETWEEN '1997-01-01' AND CURRENT_DATE
    GROUP BY 
        ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COALESCE(sr.total_revenue, 0) AS total_revenue
    FROM 
        supplier s
    LEFT JOIN 
        SupplierRevenue sr ON s.s_suppkey = sr.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_order_value,
    AVG(CASE 
            WHEN r.rnk IS NOT NULL THEN o.o_totalprice 
            ELSE NULL 
        END) AS avg_order_value,
    MAX(ts.total_revenue) AS max_supplier_revenue,
    STRING_AGG(CASE 
            WHEN ts.total_revenue > 1000000 THEN ts.s_name 
            ELSE NULL 
        END, ', ') AS high_revenue_suppliers
FROM 
    nation n
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RankedOrders r ON o.o_orderkey = r.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON ts.total_revenue = 
        (SELECT MAX(total_revenue) FROM TopSuppliers)
GROUP BY 
    n.n_name
HAVING 
    SUM(o.o_totalprice) IS NOT NULL
ORDER BY 
    customer_count DESC, total_order_value DESC;
