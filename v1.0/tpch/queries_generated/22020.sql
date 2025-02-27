WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p2.p_size FROM part p2 WHERE p2.p_retailprice > 100)
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_bal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 500
    GROUP BY c.c_custkey
),
FilteredNations AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM nation n
    WHERE n.n_comment IS NOT NULL AND n.n_comment LIKE '%important%'
),
CombStats AS (
    SELECT 
        s.s_suppkey,
        cs.total_orders,
        cs.total_spent,
        ps.part_count,
        ps.total_supply_cost
    FROM SupplierStats ps
    JOIN CustomerOrders cs ON cs.total_orders > 5
    WHERE ps.part_count > (SELECT AVG(part_count) FROM SupplierStats) 
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(cs.total_spent, 0) AS total_spent,
    r.r_name AS region_name
FROM RankedParts p
FULL OUTER JOIN CombStats s ON p.p_partkey = (SELECT MAX(ps_partkey) FROM partsupp WHERE ps_supplycost < s.total_supply_cost)
LEFT JOIN FilteredNations fn ON fn.n_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = fn.n_nationkey)
WHERE p.rn = 1 
  AND (p.p_size BETWEEN 10 AND 50 OR p.p_brand LIKE '%premium%')
ORDER BY p.p_name DESC, total_spent ASC;
