
WITH PartEnhanced AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_brand, ' ', p.p_name) AS full_name,
        LENGTH(p.p_comment) AS comment_length,
        LOWER(p.p_type) AS type_lowercase
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS supply_count,
        AVG(ps.ps_supplycost) AS average_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerWithHighOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    p.full_name,
    p.comment_length,
    p.type_lowercase,
    ss.supply_count,
    ss.average_cost,
    c.total_spent 
FROM 
    PartEnhanced p
JOIN 
    SupplierStats ss ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = ss.average_cost LIMIT 1)
JOIN 
    CustomerWithHighOrders c ON c.total_spent > (SELECT AVG(p.p_retailprice) FROM part p)
WHERE 
    p.comment_length > 20
ORDER BY 
    c.total_spent DESC, 
    ss.average_cost ASC;
