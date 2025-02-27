WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierSummary AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(l.l_shipdate) AS last_shipdate
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name, 
    r.r_name, 
    SUM(l.total_revenue) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE NULL END) AS avg_open_order_value,
    MAX(s.total_cost) AS highest_supplier_cost,
    COUNT(DISTINCT CASE WHEN lo.rn <= 5 THEN lo.o_orderkey END) AS top_orders
FROM 
    LineItemDetails l
JOIN 
    RankedOrders lo ON l.l_orderkey = lo.o_orderkey
JOIN 
    CustomerStats c ON lo.o_orderkey = c.order_count
JOIN 
    supplier s ON s.s_suppkey = l.l_orderkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
GROUP BY 
    n.n_name, 
    r.r_name 
HAVING 
    SUM(l.total_revenue) > 100000
ORDER BY 
    total_revenue DESC;
