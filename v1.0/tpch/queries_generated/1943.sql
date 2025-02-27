WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
Summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        AVG(l.l_quantity) AS avg_quantity,
        COALESCE(r.r_name, 'Unknown') AS region_name,
        COALESCE(cs.total_spent, 0) AS customer_spent,
        CASE WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active' ELSE 'Inactive' END AS order_status
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        CustomerStats cs ON cs.c_custkey = o.o_custkey
    GROUP BY 
        p.p_partkey, p.p_name, r.r_name, cs.total_spent
)
SELECT 
    s.s_name,
    s.s_acctbal,
    ss.p_partkey,
    ss.total_revenue,
    ss.total_orders,
    ss.avg_quantity,
    ss.region_name,
    ss.customer_spent,
    ss.order_status
FROM 
    RankedSuppliers s
JOIN 
    Summary ss ON s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps WHERE ps.ps_partkey = ss.p_partkey
    )
WHERE 
    s.rank = 1
ORDER BY 
    ss.total_revenue DESC, 
    s.s_acctbal DESC;
