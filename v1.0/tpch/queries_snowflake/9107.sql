
WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment,
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM part p
),
FilteredSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           COUNT(DISTINCT ps.ps_partkey) as part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) as order_count,
           SUM(o.o_totalprice) as total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING COUNT(o.o_orderkey) > 5
),
TopRegions AS (
    SELECT n.n_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) as customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_regionkey, r.r_name
    ORDER BY customer_count DESC
    LIMIT 3
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_type, 
    fs.s_name, 
    co.c_name, 
    tr.r_name,
    co.total_spent
FROM RankedParts rp
JOIN FilteredSuppliers fs ON rp.p_partkey IN (
    SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey
)
JOIN CustomerOrders co ON co.c_nationkey = fs.s_nationkey
JOIN TopRegions tr ON tr.n_regionkey = co.c_nationkey
WHERE rp.price_rank <= 5
ORDER BY co.total_spent DESC, rp.p_retailprice ASC
LIMIT 10;
