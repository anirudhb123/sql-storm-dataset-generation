
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part p1 WHERE p1.p_brand = p.p_brand)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(CASE WHEN ps.ps_availqty > 100 THEN ps.ps_supplycost ELSE 0 END) AS high_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
ConsumerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5 OR SUM(o.o_totalprice) > 1000
)
SELECT 
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    ss.high_supply_cost,
    ci.total_spent,
    ci.order_count,
    CASE 
        WHEN ci.total_spent IS NULL THEN 'No Orders'
        ELSE 'Active Customer'
    END AS customer_status
FROM 
    RankedParts rp
LEFT JOIN 
    SupplierStats ss ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = ss.high_supply_cost ORDER BY ps.ps_availqty DESC LIMIT 1)
LEFT JOIN 
    ConsumerInfo ci ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_acctbal > 100))
WHERE 
    rp.rank <= 5 AND rp.p_brand NOT LIKE 'BrandZ%'
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC
LIMIT 100 OFFSET 0;
