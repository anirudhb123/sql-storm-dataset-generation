WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_comment LIKE '%special%'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        c.orders_count,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        CustomerOrders c
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    tc.c_name,
    tc.total_spent,
    tc.orders_count
FROM 
    RankedParts rp
JOIN 
    TopCustomers tc ON tc.orders_count > 10
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_retailprice DESC, 
    tc.total_spent DESC;
