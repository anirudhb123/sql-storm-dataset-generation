WITH ranked_part AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2
        )
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
), 
supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        COUNT(ps.ps_partkey) AS parts_provided
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
)

SELECT 
    cp.c_custkey,
    cp.c_name,
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    si.nation_name,
    si.parts_provided,
    cp.order_count,
    cp.total_spent
FROM 
    ranked_part rp
JOIN 
    customer_orders cp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < rp.p_retailprice)
JOIN 
    supplier_info si ON si.parts_provided > 10
WHERE 
    rp.brand_rank <= 3
ORDER BY 
    cp.total_spent DESC, rp.p_retailprice DESC;
