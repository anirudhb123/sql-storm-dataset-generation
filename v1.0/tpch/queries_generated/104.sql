WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_size,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rnk
    FROM part p
    WHERE p.p_retailprice > 50.00
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
)
SELECT 
    co.c_name,
    rp.p_name,
    rp.p_brand,
    fs.total_supply_value,
    COALESCE(fs.total_supply_value, 0) AS adjusted_supply_value,
    RANK() OVER (PARTITION BY rp.p_type ORDER BY COALESCE(fs.total_supply_value, 0) DESC) AS supply_rank
FROM RankedParts rp
LEFT JOIN FilteredSuppliers fs ON rp.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost > 15.00
)
JOIN CustomerOrders co ON co.total_spent > 5000
WHERE rp.rnk <= 5
ORDER BY rp.p_type, supply_rank;
