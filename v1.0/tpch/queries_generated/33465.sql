WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ps.ps_availqty, 
        p.p_partkey 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        ps.ps_availqty IS NOT NULL
        
    UNION ALL
    
    SELECT 
        sc.s_suppkey, 
        sc.s_name, 
        sc.s_acctbal + (0.1 * ps.ps_supplycost), 
        ps.ps_availqty, 
        p.p_partkey 
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey 
    WHERE 
        ps.ps_supplycost < 100.00
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    sc.s_name AS supplier_name, 
    COALESCE(SUM(ao.total_revenue), 0) AS total_revenue,
    COUNT(DISTINCT ao.unique_customers) AS customer_count,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(ao.total_revenue), 0) DESC) AS revenue_rank
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplyChain sc ON ps.ps_suppkey = sc.s_suppkey
LEFT JOIN 
    AggregatedOrders ao ON p.p_partkey = ao.o_orderkey
WHERE 
    p.p_retailprice > 20.00 AND 
    (ps.ps_availqty IS NULL OR ps.ps_availqty > 10)
GROUP BY 
    p.p_partkey, p.p_name, sc.s_name
HAVING 
    COUNT(sc.s_suppkey) > 0
ORDER BY 
    revenue_rank, p.p_partkey;
