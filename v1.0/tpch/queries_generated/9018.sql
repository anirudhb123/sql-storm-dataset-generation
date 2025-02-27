WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
           p.p_size, p.p_container, p.p_retailprice, p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
), SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, COUNT(ps.ps_partkey) AS part_count, 
           SUM(ps.ps_supplycost) AS total_supplycost, AVG(s.s_acctbal) AS avg_acctbalance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent, AVG(c.c_acctbal) AS avg_acctbalance
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), RegionNationalData AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT rp.p_name, rp.p_brand, rp.p_retailprice, ss.total_supplycost, 
       cs.total_spent, r.r_name, n.n_name
FROM RankedParts rp
JOIN SupplierStats ss ON rp.p_partkey = ss.part_count
JOIN CustomerOrderStats cs ON ss.part_count = cs.order_count
JOIN RegionNationalData r ON cs.c_custkey = r.n_nationkey
WHERE rp.rn <= 5 AND ss.total_supplycost > 50000
ORDER BY rp.p_retailprice DESC, cs.total_spent DESC;
