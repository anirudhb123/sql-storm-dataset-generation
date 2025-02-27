WITH RECURSIVE supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ss.level + 1,
        ss.total_supply_cost + (ps.ps_supplycost * ps.ps_availqty) 
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        supplier_summary ss ON s.s_suppkey = ss.s_suppkey 
    WHERE 
        ss.level < 5
),
order_totals AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
),
total_by_nation AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(os.total_price) AS market_share
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        order_totals os ON c.c_custkey = os.o_orderkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(p.p_retailprice) AS average_price,
    COALESCE(ts.market_share, 0) AS market_share_by_nation
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier_summary ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    total_by_nation ts ON ss.s_nationkey = ts.n_nationkey
WHERE 
    p.p_size > 10
    AND p.p_retailprice IS NOT NULL
GROUP BY 
    p.p_name, ts.market_share
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC, average_price ASC;
