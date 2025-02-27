WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.custkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ca.total_orders,
        ca.order_count
    FROM 
        customer c
    JOIN 
        CustomerOrders ca ON c.c_custkey = ca.c_custkey
    WHERE 
        ca.total_orders > 1000
)
SELECT 
    r.r_name,
    p.p_name,
    s.s_name,
    CASE 
        WHEN av.total_availqty IS NULL THEN 0
        ELSE av.total_availqty
    END AS available_quantity,
    COALESCE(pc.total_orders, 0) AS customer_orders,
    pa.total_supplycost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAvailability av ON av.ps_partkey IN (SELECT p_partkey FROM RankedParts WHERE price_rank <= 5)
LEFT JOIN 
    FilteredCustomers pc ON pc.c_custkey = s.s_suppkey
JOIN 
    RankedParts p ON s.s_suppkey = p.p_partkey
WHERE 
    p.p_retailprice BETWEEN 50 AND 200
UNION ALL
SELECT 
    'Global' AS r_name,
    p.p_name,
    NULL AS s_name,
    NULL AS available_quantity,
    SUM(pc.total_orders) AS customer_orders,
    SUM(pa.total_supplycost) AS total_supplycost
FROM 
    RankedParts p
LEFT JOIN 
    SupplierAvailability pa ON p.p_partkey = pa.ps_partkey
LEFT JOIN 
    FilteredCustomers pc ON pc.total_orders IS NOT NULL
GROUP BY 
    p.p_name
ORDER BY 
    r_name, customer_orders DESC;
