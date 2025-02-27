WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_acctbal
    FROM 
        supplier s
),
HighBalanceSuppliers AS (
    SELECT 
        s.s_nationkey, 
        s.s_suppkey, 
        s.s_name 
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank_acctbal <= 3  -- Top 3 suppliers by account balance in each nation
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS item_count,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierOrderSummary AS (
    SELECT 
        h.s_nationkey,
        o.total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        HighBalanceSuppliers h
    JOIN 
        partsupp ps ON h.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        OrderDetails o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        h.s_nationkey, o.total_order_value
)
SELECT 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COALESCE(AVG(sos.total_order_value), 0) AS avg_order_value,
    SUM(sos.order_count) AS total_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    HighBalanceSuppliers h ON n.n_nationkey = h.s_nationkey
LEFT JOIN 
    SupplierOrderSummary sos ON h.s_nationkey = sos.s_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name;
