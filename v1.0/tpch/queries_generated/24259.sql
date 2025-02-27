WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY c.c_custkey
), 
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 5000
    GROUP BY s.s_suppkey
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
)
SELECT 
    r.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    MAX(lp.total_spent) AS highest_order_value,
    SUM(lp.order_count) AS total_orders,
    MAX(rp.p_name) AS expensive_part,
    COUNT(DISTINCT hs.s_suppkey) AS reliable_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN customer c ON c.c_nationkey = n.n_nationkey
JOIN CustomerOrders lp ON c.c_custkey = lp.c_custkey
LEFT JOIN RankedParts rp ON rp.rank = 1 AND rp.p_retailprice IS NOT NULL
LEFT JOIN HighValueSuppliers hs ON hs.avg_supply_cost < 1000
WHERE r.r_name IS NOT NULL AND r.r_name <> ''
GROUP BY r.n_name
HAVING COUNT(DISTINCT c.c_custkey) > COALESCE(NULLIF(MAX(lp.order_count), 0), 1)
ORDER BY total_orders DESC, highest_order_value DESC;
