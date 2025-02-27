WITH RECURSIVE price_ranking AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
supplier_data AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        COUNT(ps.ps_supplycost) AS supply_count
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
customer_summary AS (
    SELECT 
        c.c_custkey,
        c.c_mktsegment,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    GROUP BY c.c_custkey, c.c_mktsegment
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE WHEN ps.ps_supplycost IS NOT NULL THEN ps.ps_supplycost ELSE 0 END) AS total_supply_cost,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_net_price,
    COUNT(DISTINCT lr.s_suppkey) AS unique_suppliers,
    STRING_AGG(DISTINCT p.p_name || ' (Rank: ' || COALESCE(pr.price_rank::text, 'N/A') || ')', ', ') AS part_names_with_ranks
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier_data sd ON n.n_nationkey = sd.s_nationkey
LEFT JOIN partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN customer_summary c ON c.c_mktsegment = 'BUILDING' AND c.total_spent > (SELECT AVG(total_spent) FROM customer_summary)
LEFT JOIN price_ranking pr ON ps.ps_partkey = pr.p_partkey AND pr.price_rank = 1
LEFT JOIN orders o ON o.o_custkey = c.c_custkey AND o.o_orderstatus = 'O'
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 AND SUM(sd.s_acctbal) > 10000
ORDER BY unique_customers DESC, total_supply_cost ASC;
