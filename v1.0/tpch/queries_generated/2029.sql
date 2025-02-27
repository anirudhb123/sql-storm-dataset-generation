WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderpriority
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_orderpriority
    FROM 
        OrderSummary o
    WHERE 
        o.revenue_rank <= 10
)
SELECT 
    p.p_name,
    s.s_name,
    COALESCE(hv.o_orderkey, -1) AS high_value_order_key,
    COUNT(DISTINCT hv.o_orderkey) AS order_count,
    SUM(CASE WHEN s.s_acctbal > 10000 THEN 1 ELSE 0 END) AS high_balance_suppliers
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    HighValueOrders hv ON hv.o_orderkey IN (
        SELECT DISTINCT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey
    )
GROUP BY 
    p.p_partkey, s.s_name, hv.o_orderkey
ORDER BY 
    p.p_name, high_value_order_key DESC;
