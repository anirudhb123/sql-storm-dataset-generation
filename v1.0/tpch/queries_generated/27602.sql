WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_type, 
           p.p_size,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 10
),
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_nationkey, 
           s.s_acctbal,
           COUNT(ps.ps_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    HAVING COUNT(ps.ps_partkey) > 5
),
CustomerPurchases AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
)
SELECT rp.p_name, 
       rp.p_brand, 
       ts.s_name, 
       cp.c_name, 
       cp.total_spent
FROM RankedParts rp
JOIN TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN CustomerPurchases cp ON cp.total_spent > 1500
WHERE rp.rn <= 3
ORDER BY rp.p_brand, cp.total_spent DESC;
