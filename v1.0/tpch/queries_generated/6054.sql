WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
total_sales AS (
    SELECT 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        p.p_brand
    FROM 
        lineitem l
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_brand
),
supplier_details AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 10000
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    r.c_acctbal,
    r.c_mktsegment,
    ts.total_revenue,
    sd.s_name,
    sd.s_acctbal AS supplier_acctbal,
    sd.n_name AS supplier_nation
FROM 
    ranked_orders r
INNER JOIN 
    total_sales ts ON r.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = r.o_orderkey)
LEFT JOIN 
    supplier_details sd ON r.c_mktsegment = 'BUILDING' AND sd.s_acctbal > r.c_acctbal
WHERE 
    r.rn <= 10
ORDER BY 
    r.o_orderdate DESC, 
    total_revenue DESC;
