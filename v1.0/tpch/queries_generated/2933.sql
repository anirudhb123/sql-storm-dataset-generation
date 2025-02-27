WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
OrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey
),
CustomerSatisfaction AS (
    SELECT 
        c.c_custkey,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS returned_items,
        COUNT(l.l_orderkey) AS total_items
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cs.c_custkey) AS unique_customers,
    SUM(cs.total_orders) AS total_orders_placed,
    SUM(cs.total_spent) AS total_revenue,
    AVG(COALESCE(cs.total_spent, 0)) AS avg_spent_per_customer,
    AVG(CASE WHEN cs.returned_items > 0 THEN cs.returned_items * 1.0 / cs.total_items ELSE 0 END) AS return_rate,
    STRING_AGG(DISTINCT CONCAT_WS('-', s.s_name, s.s_acctbal), '; ') AS top_suppliers
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    OrderSummary cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    RankedSuppliers s ON s.rn = 1 AND s.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100) 
    )
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
