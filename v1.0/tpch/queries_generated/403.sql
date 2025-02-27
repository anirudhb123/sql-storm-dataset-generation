WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
        c.c_nationkey
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.nationkey,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_sales
    FROM 
        RankedOrders r
    LEFT JOIN 
        lineitem l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.price_rank <= 10
    GROUP BY 
        r.o_orderkey, r.o_orderdate, r.o_totalprice, r.nationkey
), SupplierSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        s.s_name,
        n.n_name,
        r.r_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        p.p_partkey, s.s_name, n.n_name, r.r_name
)
SELECT 
    TO.orders.o_orderkey,
    TO.o_orderdate,
    TO.o_totalprice,
    SS.s_name,
    SS.total_quantity,
    SS.total_revenue,
    CASE 
        WHEN SS.total_revenue IS NULL THEN 'No Sales'
        WHEN SS.total_revenue > TO.net_sales THEN 'Above Average'
        ELSE 'Below Average' 
    END AS sales_performance
FROM 
    TopOrders TO
LEFT JOIN 
    SupplierSales SS ON TO.nationkey = SS.n_nationkey
ORDER BY 
    TO.o_orderkey, SS.total_revenue DESC;
