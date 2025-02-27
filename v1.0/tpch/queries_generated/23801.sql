WITH RECURSIVE PriceHierarchy AS (
    SELECT 
        p_partkey,
        p_name,
        p_retailprice,
        0 AS level
    FROM 
        part
    WHERE 
        p_retailprice > (SELECT AVG(p_retailprice) FROM part WHERE p_size NOT BETWEEN 5 AND 15)
    
    UNION ALL

    SELECT 
        p.partkey,
        p.p_name,
        p.p_retailprice,
        ph.level + 1
    FROM 
        part p
    INNER JOIN 
        PriceHierarchy ph ON p.p_partkey = ph.p_partkey
    WHERE 
        ph.level < 2
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON o.o_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 0
)

SELECT 
    p.p_name,
    ph.level,
    co.c_name,
    COALESCE(co.total_orders, 0) AS orders_count,
    COALESCE(co.total_spent, 0) AS amount_spent,
    CASE 
        WHEN co.total_spent IS NULL OR co.total_spent < 100 THEN 'Low Spender' 
        WHEN co.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender' 
        ELSE 'High Spender' 
    END AS spender_category,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey = 1)) AS supplier_count
FROM 
    PriceHierarchy ph
LEFT JOIN 
    CustomerOrders co ON ph.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IN (SELECT MAX(ps_supplycost) FROM partsupp))
WHERE 
    ph.p_retailprice > 50 AND (ph.level IS NULL OR ph.level > 0)
ORDER BY 
    ph.level DESC, amount_spent DESC;

