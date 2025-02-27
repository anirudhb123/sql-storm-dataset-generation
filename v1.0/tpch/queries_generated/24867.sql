WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
), SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), HighCostSuppliers AS (
    SELECT 
        sc.ps_partkey
    FROM SupplierCosts sc
    WHERE sc.avg_supply_cost > 
        (SELECT AVG(avg_supply_cost) FROM SupplierCosts)
), RecentOrders AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(DAY, -90, GETDATE())
    GROUP BY o.o_custkey
)
SELECT 
    np.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS a_unusual_sum,
    AVG(s.s_acctbal) AS average_supplier_balance
FROM nation np
LEFT JOIN supplier s ON np.n_nationkey = s.s_nationkey
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN RankedParts rp ON l.l_partkey = rp.p_partkey
WHERE rp.rn <= 5 AND l.l_returnflag = 'R'
    AND (s.s_acctbal IS NOT NULL OR s.s_acctbal < 0) 
GROUP BY np.n_name
HAVING SUM(l.l_extendedprice) > (SELECT AVG(total_sales) FROM RecentOrders) 
   OR COUNT(DISTINCT s.s_suppkey) IS NULL
ORDER BY nation_name;

