WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    INNER JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS parts_supplied
    FROM 
        supplier s
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customers,
    COALESCE(SUM(lp.l_extendedprice), 0) AS total_lineitem_price,
    COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
    AVG(co.total_spent) AS average_spent_per_customer
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT OUTER JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM RankedParts p WHERE p.price_rank <= 5)
LEFT JOIN 
    SupplierInfo s ON s.parts_supplied > 0
WHERE 
    o.o_orderdate >= DATE '2023-01-01'
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10 AND 
    AVG(co.total_spent) IS NOT NULL
ORDER BY 
    total_lineitem_price DESC, customers DESC;
