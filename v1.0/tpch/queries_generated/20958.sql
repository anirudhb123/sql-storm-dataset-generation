WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        p.p_mfgr,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS recent_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
FinalReport AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_retailprice,
        ss.s_name,
        cs.c_name,
        cs.order_count,
        cs.total_spent,
        COALESCE(cs.total_spent / NULLIF(cs.order_count, 0), 0) AS avg_spent_per_order
    FROM RankedParts rp
    FULL OUTER JOIN SupplierStats ss ON rp.p_partkey = ss.s_suppkey
    LEFT JOIN CustomerOrders cs ON cs.order_count > 0
    WHERE rp.rn = 1 OR ss.total_available > 100
)
SELECT 
    fr.p_partkey,
    fr.p_name,
    fr.p_retailprice,
    fr.s_name,
    fr.c_name,
    fr.order_count,
    fr.total_spent,
    fr.avg_spent_per_order,
    CASE 
        WHEN fr.avg_spent_per_order IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM FinalReport fr
WHERE fr.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY fr.avg_spent_per_order DESC NULLS LAST;
