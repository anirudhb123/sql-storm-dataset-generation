WITH RECURSIVE price_analysis AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0
            ELSE p.p_retailprice * (1 - COALESCE(AVG(l.l_discount) OVER (PARTITION BY l.l_partkey) , 0)) 
            END AS adjusted_price
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey 
    WHERE 
        p.p_size > 10

    UNION ALL

    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0
            ELSE p.p_retailprice * (1 - COALESCE(AVG(l.l_discount) OVER (PARTITION BY l.l_partkey) , 0)) * 0.9
            END
    FROM 
        part p
    JOIN 
        price_analysis pa ON pa.p_partkey = p.p_partkey
    WHERE 
        p.p_container LIKE 'MED BAG%'
        AND pa.adjusted_price < 100
),

high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
),

customer_supplier AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey
    FROM 
        customer c 
    LEFT JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
)

SELECT 
    DISTINCT pa.p_name,
    pa.adjusted_price,
    COUNT(DISTINCT h.o_orderkey) AS total_orders,
    SUM(cs.s_acctbal) AS total_supplier_balance
FROM 
    price_analysis pa
LEFT JOIN 
    high_value_orders h ON h.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pa.p_partkey)
LEFT JOIN 
    customer_supplier cs ON cs.c_suppkey = pa.p_partkey
WHERE 
    pa.adjusted_price IS NOT NULL 
    AND pa.adjusted_price > 50 
    AND EXISTS (SELECT 1 FROM region r WHERE r.r_name = 'ASIA')
GROUP BY 
    pa.p_name, pa.adjusted_price
HAVING 
    COUNT(DISTINCT h.o_orderkey) > 10
ORDER BY 
    total_orders DESC;
