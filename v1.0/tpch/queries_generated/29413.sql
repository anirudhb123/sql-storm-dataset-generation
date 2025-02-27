WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 50 AND p.p_retailprice > 100
), FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_acctbal,
        s.s_comment,
        n.n_name AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal >= (SELECT AVG(s2.s_acctbal) FROM supplier s2)
), CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    r.p_partkey,
    r.p_name,
    r.p_brand,
    r.p_type,
    r.p_retailprice,
    fs.s_name AS supplier_name,
    fs.supplier_nation,
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent
FROM RankedParts r
JOIN FilteredSuppliers fs ON r.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp WHERE ps_partkey = r.p_partkey))
JOIN CustomerOrders co ON co.total_orders > 5
WHERE r.rn <= 5
ORDER BY r.p_retailprice DESC, co.total_spent DESC;
