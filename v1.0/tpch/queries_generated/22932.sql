WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost) > 10000
),
CustomerOrders AS (
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
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 5
)
SELECT 
    p.p_name,
    p.p_retailprice,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    c.c_name AS customer_name,
    c.order_count,
    c.total_spent,
    RANK() OVER (PARTITION BY c.c_custkey ORDER BY c.total_spent DESC) AS cust_rank
FROM 
    RankedParts p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    HighValueSuppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerOrders c ON RANDOM() < 0.1 OR c.order_count < 3
WHERE 
    p.price_rank <= 5
AND 
    (c.total_spent > 500 OR s.total_supply_cost IS NULL)
ORDER BY 
    p.p_retailprice DESC, 
    c.total_spent ASC, 
    cust_rank;
