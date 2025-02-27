WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
    ORDER BY 
        order_count DESC
    LIMIT 5
)
SELECT 
    ns.n_name AS nation_name,
    cs.c_name AS customer_name,
    cs.total_spent,
    cs.order_count,
    os.total_revenue,
    rs.s_name AS top_supplier
FROM 
    TopNations ns
JOIN 
    customer c ON c.c_nationkey = ns.n_nationkey
JOIN 
    CustomerSummary cs ON cs.c_custkey = c.c_custkey
JOIN 
    OrderSummary os ON os.o_orderkey = (
        SELECT MIN(o_orderkey) 
        FROM orders 
        WHERE o_custkey = cs.c_custkey
    )
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND rs.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand LIKE 'Brand#%'
        ORDER BY ps.ps_supplycost ASC 
        LIMIT 1
    )
WHERE 
    cs.last_order_date >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY 
    cs.total_spent DESC, cs.order_count DESC;
