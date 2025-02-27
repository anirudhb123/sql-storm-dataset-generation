WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
),
SupplierStatistics AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_supply_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CONCAT(s.s_name, ' - ', s.s_acctbal) AS supplier_info,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    cs.order_count AS customer_order_count,
    ts.supplier_info,
    o.order_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    region r ON c.c_nationkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderCounts cs ON cs.c_custkey = c.c_custkey
INNER JOIN 
    TopSuppliers ts ON ts.s_suppkey = ps.ps_suppkey
WHERE 
    l.l_shipdate >= current_date - INTERVAL '1 year'
    AND (o.o_orderstatus = 'F' OR o.o_orderstatus = 'P')
GROUP BY 
    r.r_name, p.p_name, cs.order_count, ts.supplier_info, o.order_rank
ORDER BY 
    revenue DESC, r.r_name, p.p_name;
