WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, c_mktsegment, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000

    UNION ALL

    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, c.c_mktsegment, cc.level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_nationkey = cc.c_nationkey
    WHERE c.c_acctbal > cc.c_acctbal
),
RankedPart AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as price_rank
    FROM part p
),
SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name,
           COUNT(DISTINCT s.s_suppkey) as supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ss.total_supply_cost) AS avg_supply_cost,
    MAX(rp.p_name) AS highest_priced_part,
    COALESCE(MAX(cc.c_acctbal), 0) AS max_customer_acctbal,
    STRING_AGG(DISTINCT rp.p_name) AS parts_list
FROM NationRegion n
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN partsupp ps ON ps.ps_partkey IN (SELECT p_partkey FROM RankedPart WHERE price_rank = 1)
LEFT JOIN SupplierStats ss ON ss.s_suppkey = ps.ps_suppkey
LEFT JOIN RankedPart rp ON rp.p_partkey = ps.ps_partkey
LEFT JOIN CustomerCTE cc ON cc.c_custkey = c.c_custkey
WHERE c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_available_quantity DESC NULLS LAST;
