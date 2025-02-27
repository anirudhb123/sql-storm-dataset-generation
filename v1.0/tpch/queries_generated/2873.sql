WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice > 100
), SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    si.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.total_spent,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Made'
    END AS order_status
FROM RankedParts p
JOIN SupplierInfo si ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = si.s_suppkey)
LEFT JOIN CustomerOrders co ON co.order_count > 0
WHERE p.rn <= 5
AND (p.p_brand LIKE 'Brand%')
ORDER BY p.p_retailprice DESC, si.total_supply_cost DESC;
