WITH RECURSIVE nation_hierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
),
supplier_summary AS (
    SELECT s.s_nationkey, 
           COUNT(s.s_suppkey) AS total_suppliers, 
           SUM(s.s_acctbal) AS total_balance
    FROM supplier s
    GROUP BY s.s_nationkey
),
part_supply AS (
    SELECT p.p_partkey, 
           p.p_name,
           ps.ps_availqty,
           ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    s.total_suppliers,
    s.total_balance,
    ps.p_name AS part_name,
    ps.ps_availqty,
    ps.ps_supplycost,
    CASE 
        WHEN ps.ps_supplycost IS NULL THEN 'No cost available'
        ELSE CAST(ps.ps_supplycost AS varchar) 
    END AS supply_cost_string,
    (SELECT AVG(l.l_extendedprice) 
     FROM lineitem l 
     WHERE l.l_orderkey IN (SELECT o.o_orderkey 
                            FROM orders o 
                            WHERE o.o_custkey = c.c_custkey)) AS avg_extended_price
FROM nation n
LEFT JOIN supplier_summary s ON n.n_nationkey = s.s_nationkey
LEFT JOIN part_supply ps ON ps.rn = 1
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE s.total_balance > 1000
AND n.n_name LIKE 'A%'
ORDER BY s.total_suppliers DESC, s.total_balance ASC;
