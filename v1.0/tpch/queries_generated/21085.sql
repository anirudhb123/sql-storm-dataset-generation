WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) -- filtering above average retail price
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS available_parts, 
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 3 -- suppliers with more than 3 available parts
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
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 100.00 -- customers with account balance above 100
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 500.00 -- customers who spent more than 500
)
SELECT 
    r.r_name AS region,
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    p.p_retailprice,
    sd.total_supply_cost,
    CASE 
        WHEN p.brand_rank = 1 THEN 'Top Brand Part' 
        ELSE 'Other Part' 
    END AS part_category 
FROM 
    RankedParts p
JOIN 
    SupplierDetails sd ON sd.available_parts > 0
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = o.o_custkey
JOIN 
    nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = sd.s_name)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    p.p_retailprice + COALESCE(sd.total_supply_cost, 0) < 2000.00 
    AND l.l_returnflag = 'N'
UNION ALL
SELECT 
    r.r_name AS region,
    'Unknown Part' AS part_name,
    sd.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    NULL AS retail_price,
    sd.total_supply_cost,
    'Missing Part' AS part_category
FROM 
    SupplierDetails sd
LEFT JOIN 
    CustomerOrders co ON co.customer_name IS NOT NULL
JOIN 
    nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = sd.s_name)
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    NOT EXISTS (SELECT 1 FROM RankedParts rp WHERE rp.p_partkey = sd.available_parts)
ORDER BY 
    region, part_category DESC, total_spent DESC;
