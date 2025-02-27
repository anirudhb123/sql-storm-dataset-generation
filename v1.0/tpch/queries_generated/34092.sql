WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        0 AS depth
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        depth + 1
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        SupplyChain sc ON ps.ps_partkey = sc.ps_partkey
    WHERE 
        sc.depth < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    p.p_name,
    SUM(sc.ps_availqty) AS total_available,
    AVG(sc.ps_supplycost) AS avg_supply_cost,
    os.total_revenue,
    n.n_name AS nation_name
FROM 
    part p
LEFT JOIN 
    SupplyChain sc ON p.p_partkey = sc.ps_partkey
LEFT JOIN 
    OrderSummary os ON os.o_orderkey = sc.s_suppkey
LEFT JOIN 
    nation n ON sc.s_nationkey = n.n_nationkey
WHERE 
    (sc.ps_availqty IS NOT NULL OR os.total_revenue IS NOT NULL)
    AND p.p_retailprice > 100.00
    AND n.n_name IS NOT NULL
GROUP BY 
    p.p_name, os.total_revenue, n.n_name
HAVING 
    SUM(sc.ps_availqty) > 0
ORDER BY 
    total_available DESC NULLS LAST;
