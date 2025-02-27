WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 1 AS level
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, sh.level + 1
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),

PartSupplierStats AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           AVG(l.l_extendedprice) AS avg_extended_price
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),

SupplierAverage AS (
    SELECT sh.nation_name, AVG(sh.s_acctbal) AS avg_account_balance
    FROM SupplierHierarchy sh
    GROUP BY sh.nation_name
)

SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    ps.total_supply_cost,
    pas.avg_extended_price,
    sa.avg_account_balance
FROM part p
LEFT JOIN PartSupplierStats ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN SupplierAverage sa ON sa.nation_name = (
    SELECT n.n_name 
    FROM nation n 
    WHERE n.n_nationkey = (
        SELECT s.s_nationkey 
        FROM supplier s 
        JOIN partsupp psu ON s.s_suppkey = psu.ps_suppkey 
        WHERE psu.ps_partkey = p.p_partkey 
        LIMIT 1
    )
)
FULL OUTER JOIN (
    SELECT DISTINCT l.l_suppkey, l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_returnflag = 'R'
) returned ON returned.l_suppkey = ps.ps_suppkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY total_supply_cost DESC, avg_extended_price ASC;
