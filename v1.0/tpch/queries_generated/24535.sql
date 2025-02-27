WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 10 AND 20
),
supplier_avg AS (
    SELECT 
        s.s_nationkey,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
customer_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, c.c_name
),
nation_region AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name ASC) AS nation_rank
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    rp.p_name,
    rp.p_retailprice,
    COALESCE(s.avg_acctbal, 0) AS avg_supplier_acctbal,
    COALESCE(co.revenue, 0) AS total_revenue,
    CASE 
        WHEN nr.nation_rank IS NULL THEN 'No Nation'
        ELSE nr.r_name 
    END AS nation_name
FROM 
    ranked_parts rp
LEFT JOIN 
    supplier_avg s ON s.s_nationkey IN (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_nationkey = rp.p_partkey)
LEFT JOIN 
    customer_orders co ON co.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'John Doe' AND c.c_acctbal > 1000)
LEFT JOIN 
    nation_region nr ON nr.n_nationkey = COALESCE(NULLIF(rp.p_partkey, 0), 1)
WHERE 
    rp.rank <= 5
ORDER BY 
    rp.p_retailprice DESC, avg_supplier_acctbal ASC
FETCH FIRST 10 ROWS ONLY;
