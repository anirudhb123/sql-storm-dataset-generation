
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
ExplodedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment,
        COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
),
MatchingNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON s.s_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        n.n_name NOT LIKE '%land%'
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    e.p_partkey,
    e.p_name,
    e.total_supply_cost,
    COALESCE(r.s_name, 'No Supplier') AS supplier_name,
    m.n_name AS nation_name,
    m.order_count
FROM 
    ExplodedParts e
FULL OUTER JOIN 
    RankedSuppliers r ON e.p_partkey = r.s_suppkey
LEFT JOIN 
    MatchingNations m ON r.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey = e.p_partkey 
                                          LIMIT 1)
WHERE 
    (e.total_supply_cost > 1000 OR r.rn IS NULL)
    AND (r.s_name IS NOT NULL OR m.order_count > 5)
ORDER BY 
    e.total_supply_cost DESC, m.order_count ASC
LIMIT 10 OFFSET 10;
