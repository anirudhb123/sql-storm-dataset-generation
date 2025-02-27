WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
OrdersByCustomer AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
LineItemSummary AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(rs.rank, 0) AS supplier_rank,
    obs.total_orders,
    obs.total_spent,
    lis.total_revenue,
    lis.avg_quantity,
    CASE 
        WHEN lis.total_revenue > 100000 THEN 'High Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.ps_partkey
LEFT JOIN 
    OrdersByCustomer obs ON obs.c_custkey = (
        SELECT 
            c.c_custkey 
        FROM 
            customer c 
        JOIN 
            orders o ON c.c_custkey = o.o_custkey 
        WHERE 
            o.o_orderkey = (
                SELECT MAX(o2.o_orderkey) 
                FROM orders o2 
                WHERE o2.o_custkey = obs.c_custkey
            )
        LIMIT 1
    )
LEFT JOIN 
    LineItemSummary lis ON p.p_partkey = lis.l_partkey
WHERE 
    (rs.s_acctbal IS NULL OR rs.s_acctbal > 5000) 
    AND (obs.total_orders IS NULL OR obs.total_orders > 0)
ORDER BY 
    lis.total_revenue DESC, 
    p.p_partkey;
