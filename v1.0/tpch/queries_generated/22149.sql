WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level,
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal * 0.9,  -- Simulating a 10% decrease for illustration
        sh.level + 1,
        CONCAT(sh.s_comment, ' | ', s.s_comment)
    FROM supplier_hierarchy sh
    JOIN supplier s ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 5
), 
rich_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown' 
            WHEN c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2) THEN 'Rich'
            ELSE 'Average'
        END AS wealth_status
    FROM customer c
    WHERE c.c_comment NOT LIKE '%fake%'
),
suppliers_with_orders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT o.o_orderkey) > 1
),
aggregated_data AS (
    SELECT 
        p.p_partkey,
        MAX(LENGTH(p.p_name)) AS max_part_name_length,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sh.s_name AS supplier_name,
    rc.c_name AS rich_customer_name,
    ag.max_part_name_length,
    ag.avg_supply_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_suppkey
JOIN rich_customers rc ON rc.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey ORDER BY c.c_acctbal DESC LIMIT 1)
JOIN aggregated_data ag ON ag.p_partkey = (SELECT p.p_partkey FROM part p ORDER BY LENGTH(p.p_name) DESC LIMIT 1)
WHERE sh.level IS NOT NULL
AND rc.wealth_status = 'Rich'
ORDER BY ag.avg_supply_cost DESC, sh.s_name ASC;
