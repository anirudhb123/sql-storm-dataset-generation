WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),

SupplierStats AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),

HighValuePart AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_container ORDER BY p.p_retailprice DESC) AS rank_container
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) * 1.2 FROM part p2)
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS total_returns,
    COALESCE(SUM(lo.o_totalprice), 0) AS total_order_value,
    COUNT(DISTINCT hi.p_partkey) AS high_value_part_count,
    MAX(ss.total_supply_cost) AS max_supplier_cost,
    COUNT(DISTINCT oi.o_orderkey) AS distinct_order_count
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem li ON ps.ps_partkey = li.l_partkey
LEFT JOIN RankedOrders lo ON li.l_orderkey = lo.o_orderkey
LEFT JOIN HighValuePart hi ON ps.ps_partkey = hi.p_partkey
LEFT JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
WHERE (n.n_comment IS NULL OR n.n_comment LIKE '%important%') 
AND (s.s_acctbal > 1000 OR s.s_comment IS NOT NULL)
GROUP BY r.r_name, n.n_name, s.s_name
HAVING COUNT(DISTINCT lo.o_orderkey) > 10
   AND (MAX(li.l_tax) IS NULL OR SUM(li.l_extendedprice) > 50000)
ORDER BY r.r_name, n.n_name, s.s_name;
