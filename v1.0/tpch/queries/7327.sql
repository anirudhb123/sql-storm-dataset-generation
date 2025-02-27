WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
top_customers AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.c_acctbal
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank <= 5
),
supplier_parts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, p.p_name, p.p_brand, p.p_mfgr
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
)
SELECT 
    tc.c_name,
    tc.o_orderkey,
    tc.o_orderdate,
    tc.o_totalprice,
    sp.p_name,
    sp.p_brand,
    sp.total_available
FROM 
    top_customers tc
JOIN 
    high_value_orders hvo ON tc.o_orderkey = hvo.o_orderkey
JOIN 
    supplier_parts sp ON sp.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = tc.o_orderkey)
WHERE 
    sp.total_available > 50
ORDER BY 
    tc.o_orderdate DESC, tc.o_totalprice DESC;