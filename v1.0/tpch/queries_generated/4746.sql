WITH SupplierMetrics AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PerformanceBenchmark AS (
    SELECT 
        ns.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(s.total_available_quantity) AS avg_available_quantity
    FROM 
        nation ns
    JOIN 
        supplier s ON ns.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        ns.n_name
)
SELECT 
    pb.n_name,
    pb.total_revenue,
    pb.order_count,
    COALESCE(cs.total_orders, 0) AS total_customer_orders,
    COALESCE(cs.total_spent, 0) AS total_customer_spent,
    CASE 
        WHEN pb.order_count > 100 THEN 'High'
        WHEN pb.order_count BETWEEN 50 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS order_performance,
    NULLIF(pb.avg_available_quantity, 0) AS avg_quantity_or_null
FROM 
    PerformanceBenchmark pb
LEFT OUTER JOIN 
    CustomerStats cs ON cs.total_spent > 10000
ORDER BY 
    total_revenue DESC, order_count ASC;
