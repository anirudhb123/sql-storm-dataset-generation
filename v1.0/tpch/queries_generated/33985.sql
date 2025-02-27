WITH RECURSIVE SupplyChain AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment,
        1 AS level
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000

    UNION ALL

    SELECT 
        n.n_nationkey, 
        n.n_name, 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_comment,
        level + 1
    FROM 
        SupplyChain sc
    JOIN 
        supplier s ON s.s_suppkey = (sc.s_suppkey + 1) -- simulate a hierarchical relationship
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 5000 AND level < 3
),
AggregatedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT l.l_orderkey) AS lineitem_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' 
        AND l.l_shipdate < '2023-12-31'
    GROUP BY 
        p.p_partkey, p.p_name
),
FinalData AS (
    SELECT 
        sc.n_name AS nation_name,
        ad.p_name AS part_name,
        ad.total_revenue,
        ad.order_count,
        ad.lineitem_count,
        RANK() OVER (PARTITION BY sc.n_name ORDER BY ad.total_revenue DESC) AS revenue_rank
    FROM 
        SupplyChain sc
    JOIN 
        AggregatedData ad ON sc.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = ad.p_partkey)
)
SELECT 
    nation_name, 
    part_name, 
    total_revenue,
    order_count,
    lineitem_count
FROM 
    FinalData
WHERE 
    revenue_rank <= 5
ORDER BY 
    nation_name, 
    total_revenue DESC;
