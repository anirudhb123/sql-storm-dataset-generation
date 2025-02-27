WITH RECURSIVE regional_suppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_regionkey IN (SELECT r.r_regionkey 
                             FROM region r 
                             WHERE r.r_name LIKE 'A%')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_regionkey
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN regional_suppliers r ON s.s_nationkey = r.n_regionkey
    WHERE r.s_acctbal > 1000.00
),
filtered_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_price
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
    GROUP BY l.l_orderkey, l.l_partkey
),
supply_costs AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_partkey, 
    p.p_name,
    COALESCE(r.s_name, 'UNKNOWN') AS supplier_name,
    COALESCE(fp.max_price, 0) AS max_discounted_price,
    COALESCE(sc.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN COALESCE(fp.max_price, 0) > COALESCE(sc.total_supply_cost, 0) THEN 'More Costly'
        ELSE 'Less Costly'
    END AS cost_comparison
FROM part p
LEFT JOIN regional_suppliers r ON p.p_partkey = r.s_suppkey
LEFT JOIN filtered_lineitems fp ON p.p_partkey = fp.l_partkey
LEFT JOIN supply_costs sc ON p.p_partkey = sc.ps_partkey
WHERE (p.p_size BETWEEN 10 AND 20) 
  AND (p.p_retailprice IS NOT NULL AND p.p_retailprice < 100)
  AND (r.n_regionkey IS NULL OR r.n_regionkey NOT IN (1, 2, 3))
ORDER BY p.p_partkey DESC, cost_comparison;
