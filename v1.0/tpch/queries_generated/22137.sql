WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 10)
),
nations_with_suppliers AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT 
    r.r_name,
    np.n_name,
    np.supplier_count,
    rp.p_name,
    COALESCE(NULLIF(rp.p_retailprice, 0), 1) AS adjusted_price,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    region r
INNER JOIN 
    nations_with_suppliers np ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = np.n_name LIMIT 1)
LEFT JOIN 
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O' AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31')
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    ranked_parts rp ON ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = np.n_name))
WHERE 
    l.l_returnflag = 'N' AND 
    l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY 
    r.r_name, np.n_name, np.supplier_count, rp.p_name, rp.p_retailprice
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(l2.l_extendedprice) FROM lineitem l2 WHERE l2.l_shipdate < current_date)
ORDER BY 
    total_revenue DESC, r.r_name, np.n_name;
