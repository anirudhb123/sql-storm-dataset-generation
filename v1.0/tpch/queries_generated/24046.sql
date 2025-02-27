WITH RECURSIVE price_ranks AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        DENSE_RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), 
nation_avg AS (
    SELECT 
        n.n_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey
), 
order_status AS (
    SELECT 
        o.o_orderstatus,
        COUNT(*) AS order_count
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2020-01-01' 
        AND o.o_orderdate < DATE '2021-01-01'
    GROUP BY 
        o.o_orderstatus
)
SELECT 
    n.n_name,
    COALESCE(na.avg_acctbal, 0) AS avg_nation_acctbal,
    COUNT(DISTINCT ps.ps_supplycost) AS unique_supply_costs,
    SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_orderkey) AS total_price_per_order,
    SUM(CASE WHEN ps.ps_supplycost < (SELECT MAX(p.p_retailprice) FROM part p) 
              THEN ps.ps_supplycost ELSE NULL END) AS discounted_supply_costs,
    COUNT(o.o_orderstatus) FILTER (WHERE o.o_orderstatus = 'F') AS finished_orders,
    MAX(CASE WHEN p.price_rank IS NULL THEN 0 ELSE p.price_rank END) AS max_price_rank
FROM 
    lineitem l
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    nation_avg na ON n.n_nationkey = na.n_nationkey
JOIN 
    order_status o ON l.l_orderkey IN (SELECT o_orderkey FROM orders)
CROSS JOIN 
    price_ranks p
WHERE 
    l.l_shipdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    n.n_name, na.avg_acctbal
HAVING 
    unique_supply_costs > 0
ORDER BY 
    n.n_name;
