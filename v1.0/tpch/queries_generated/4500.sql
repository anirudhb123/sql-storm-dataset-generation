WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS supplier_parts_count,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COALESCE(SUM(req.total_revenue), 0) AS total_revenue,
    EXISTS (
        SELECT 1 
        FROM SupplierSummary ss 
        WHERE ss.total_supplycost > 100000
    ) AS sufficient_supply
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    (SELECT DISTINCT o.o_orderkey, o.o_orderstatus, r.o_orderdate, d1.total_revenue 
     FROM RankedOrders d1
     JOIN orders o ON d1.o_orderkey = o.o_orderkey) req ON req.o_orderkey = n.n_nationkey
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 2
ORDER BY 
    total_revenue DESC
LIMIT 10;
