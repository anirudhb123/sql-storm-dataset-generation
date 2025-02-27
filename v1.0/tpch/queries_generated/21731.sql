WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_per_nation
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rank_by_status
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 100.00
),
NationsWithLimitedSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) < 5
)
SELECT 
    ps.ps_partkey,
    p.p_name,
    COALESCE(SUM(CASE WHEN l.l_discount > 0.10 THEN l.l_extendedprice * (1 - l.l_discount) END), 0) AS total_discounted_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    NS.n_name AS nation_name,
    rss.s_suppkey AS ranked_supplier_id
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
INNER JOIN 
    RankedSuppliers rss ON rss.rank_per_nation = 1 AND rss.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    NationsWithLimitedSuppliers NS ON rss.s_nationkey = NS.n_nationkey
WHERE 
    p.p_size IS NOT NULL
GROUP BY 
    ps.ps_partkey, p.p_name, NS.n_name, rss.s_suppkey
HAVING 
    total_discounted_price > (SELECT AVG(total) FROM (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total 
    FROM lineitem l GROUP BY l.l_orderkey) AS averages)
ORDER BY 
    total_discounted_price DESC, p.p_name ASC
LIMIT 50;
