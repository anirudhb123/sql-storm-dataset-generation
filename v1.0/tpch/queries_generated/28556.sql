WITH part_details AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment,
        COUNT(ps.ps_partkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_container, p.p_retailprice, p.p_comment
),
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
supplier_info AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pd.p_name AS part_name,
    pd.p_retailprice,
    pd.supplier_count,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    si.s_name AS supplier_name,
    si.s_acctbal,
    si.nation_name,
    si.region_name
FROM 
    part_details pd
JOIN 
    lineitem l ON pd.p_partkey = l.l_partkey
JOIN 
    customer_orders co ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey)
JOIN 
    supplier_info si ON l.l_suppkey = si.s_suppkey
WHERE 
    pd.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    pd.p_retailprice DESC, co.total_spent DESC;
