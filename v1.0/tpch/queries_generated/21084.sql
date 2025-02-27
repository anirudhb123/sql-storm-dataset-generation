WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders AS o
    JOIN 
        customer AS c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
supplier_part_avg_cost AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        partsupp AS ps
    GROUP BY 
        ps.ps_partkey
),
high_cost_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        p.p_retailprice,
        sp.avg_supplycost,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0
            ELSE p.p_retailprice - sp.avg_supplycost
        END AS price_difference
    FROM 
        part AS p
    LEFT JOIN 
        supplier_part_avg_cost AS sp ON p.p_partkey = sp.ps_partkey
    WHERE 
        price_difference > 0
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM 
    ranked_orders AS o
JOIN 
    lineitem AS l ON o.o_orderkey = l.l_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    high_cost_parts AS p ON l.l_partkey = p.p_partkey
WHERE 
    o.order_rank <= 5 AND 
    (l.l_returnflag IS NULL OR l.l_returnflag <> 'R') AND 
    (l.l_shipmode = 'AIR' OR l.l_shipmode IS NULL)
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC;
