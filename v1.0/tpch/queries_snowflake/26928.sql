
WITH RankedProducts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY REGEXP_SUBSTR(p.p_name, '^[^ ]+') ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_retailprice > 0
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    rp.p_container,
    rp.p_retailprice,
    co.order_count,
    co.total_spent,
    (CASE 
        WHEN co.order_count > 10 THEN 'Frequent Buyer'
        WHEN co.order_count BETWEEN 5 AND 10 THEN 'Moderate Buyer'
        ELSE 'Rare Buyer'
        END) AS customer_category
FROM 
    RankedProducts rp
JOIN 
    CustomerOrders co ON co.c_custkey = rp.p_partkey
WHERE 
    rp.rnk = 1
ORDER BY 
    rp.p_retailprice DESC, 
    co.total_spent DESC;
