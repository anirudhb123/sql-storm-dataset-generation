
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > (SELECT AVG(p2.p_size) FROM part p2 WHERE p2.p_type = p.p_type)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(CASE WHEN s.s_acctbal IS NOT NULL THEN s.s_acctbal ELSE 0 END) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        CASE WHEN n.n_comment IS NULL THEN 'No Comment' ELSE n.n_comment END AS nation_comment
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%N%')
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    ss.total_supply_cost,
    co.order_count,
    co.total_spent,
    fn.n_name,
    fn.nation_comment
FROM RankedParts rp
LEFT JOIN SupplierStats ss ON ss.total_parts > 5
JOIN CustomerOrders co ON co.order_count > (SELECT AVG(order_count) FROM CustomerOrders)
JOIN FilteredNations fn ON fn.n_nationkey = (SELECT MIN(n.n_nationkey) FROM FilteredNations n WHERE n.n_name = 'GERMANY')
WHERE rp.rn <= 10
  AND (rp.p_retailprice IS NOT NULL OR rp.p_size BETWEEN 1 AND 10)
ORDER BY rp.p_retailprice DESC NULLS LAST
LIMIT 100 OFFSET (SELECT COUNT(*) / 2 FROM part WHERE p_retailprice > 100);
