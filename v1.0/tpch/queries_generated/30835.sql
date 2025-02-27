WITH RECURSIVE SupplyChain AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT 
        sc.p_partkey,
        sc.p_name,
        s.s_suppkey,
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        SupplyChain sc
    JOIN 
        partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
),
NationSupplier AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey, c.c_name
)
SELECT 
    n.n_name,
    COALESCE(ss.p_name, 'Unknown Part') AS part_name,
    od.total_revenue,
    n.total_acctbal,
    CASE 
        WHEN od.revenue_rank = 1 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_rank
FROM 
    NationSupplier n
LEFT JOIN 
    SupplyChain ss ON ss.s_suppkey = n.n_nationkey
LEFT JOIN 
    OrderDetails od ON od.c_custkey = n.n_nationkey
WHERE 
    n.total_acctbal > 1000
ORDER BY 
    n.n_name, total_revenue DESC;
