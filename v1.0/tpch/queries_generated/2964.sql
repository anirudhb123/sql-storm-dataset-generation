WITH RECURSIVE AvgCosts AS (
    SELECT 
        ps_partkey,
        AVG(ps_supplycost) as avg_supplycost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_within_nation
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(co.total_spent) AS nation_total_spent
    FROM 
        nation n
    LEFT JOIN 
        CustomerOrders co ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
    GROUP BY 
        n.n_nationkey
    HAVING 
        SUM(co.total_spent) > 100000
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    ac.avg_supplycost,
    hn.nation_total_spent
FROM 
    part p
LEFT JOIN 
    AvgCosts ac ON p.p_partkey = ac.ps_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    HighValueNations hn ON pn.n_nationkey = 
        (SELECT 
            DISTINCT n.n_nationkey 
         FROM 
            supplier s 
         JOIN 
            nation n ON s.s_nationkey = n.n_nationkey 
         WHERE 
            s.s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey)
        )
WHERE 
    (p.p_retailprice - COALESCE(ac.avg_supplycost, 0)) > 50
ORDER BY 
    hn.nation_total_spent DESC NULLS LAST;
