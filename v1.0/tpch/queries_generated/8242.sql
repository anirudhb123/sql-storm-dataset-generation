WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_revenue
    FROM 
        RankedOrders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.rank <= 10
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_supplier_revenue
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey 
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    s.s_suppkey,
    s.s_name,
    sr.total_supplier_revenue,
    tor.total_revenue
FROM 
    SupplierRevenue sr
JOIN 
    supplier s ON sr.s_suppkey = s.s_suppkey
JOIN 
    TopRevenueOrders tor ON tor.o_orderkey IN (
        SELECT 
            distinct o_orderkey 
        FROM 
            orders 
        WHERE 
            o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    )
ORDER BY 
    sr.total_supplier_revenue DESC,
    tor.total_revenue DESC;
