
WITH nation_supplier AS (
    SELECT n.n_name, s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost 
    FROM nation n 
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY n.n_name, s.s_suppkey 
),
top_nations AS (
    SELECT n_name, SUM(total_cost) AS nation_total_cost 
    FROM nation_supplier 
    GROUP BY n_name 
    ORDER BY nation_total_cost DESC 
    LIMIT 5 
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_mfgr, 
    p.p_brand, 
    p.p_type, 
    p.p_retailprice, 
    tn.n_name, 
    tn.nation_total_cost 
FROM 
    part p 
JOIN 
    top_nations tn ON tn.n_name = (
        SELECT n.n_name 
        FROM nation n 
        JOIN supplier s ON n.n_nationkey = s.s_nationkey 
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
        WHERE ps.ps_partkey = p.p_partkey 
        GROUP BY n.n_name 
        ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
ORDER BY 
    p.p_retailprice DESC;
