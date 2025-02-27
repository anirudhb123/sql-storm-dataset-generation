WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
), 
SupplierPurchases AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        s.s_nationkey
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        l.l_shipdate >= DATE '2022-01-01' AND l.l_shipdate < DATE '2023-01-01'
    GROUP BY 
        ps.ps_partkey, s.s_nationkey
), 
TopSuppliers AS (
    SELECT 
        n.n_name,
        SUM(sp.total_revenue) AS total_revenue
    FROM 
        SupplierPurchases sp
    JOIN 
        nation n ON sp.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
    ORDER BY 
        total_revenue DESC
    LIMIT 5
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    ts.n_name AS top_supplier_name,
    ts.total_revenue
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ro.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
        JOIN nation n ON s.s_nationkey = n.n_nationkey 
        WHERE n.n_name = ts.n_name
    )
WHERE 
    ro.rnk <= 10
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;
