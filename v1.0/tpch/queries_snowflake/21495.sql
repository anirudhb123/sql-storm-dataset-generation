
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
        WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%a%')
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
max_part AS (
    SELECT p.p_partkey, p.p_name, 
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
)
SELECT 
    n.n_name, 
    sh.s_name,
    p.p_name,
    ps.total_avail_qty,
    COALESCE(NULLIF(sh.s_acctbal, 0), -1) AS supplier_account_balance,
    (CASE 
        WHEN ps.avg_supply_cost < 10 THEN 'Low'
        WHEN ps.avg_supply_cost BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'High'
    END) AS supply_cost_category
FROM 
    supplier_hierarchy sh
JOIN 
    nation n ON sh.s_nationkey = n.n_nationkey
JOIN 
    part_supplier ps ON sh.s_suppkey = ps.ps_suppkey
JOIN 
    max_part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.rn <= 10
    AND sh.s_acctbal IS NOT NULL
ORDER BY 
    n.n_name, 
    sh.s_name, 
    ps.total_avail_qty DESC
OFFSET 3 ROWS FETCH NEXT 5 ROWS ONLY;
