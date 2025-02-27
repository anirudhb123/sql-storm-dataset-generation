WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier 
        WHERE s_acctbal IS NOT NULL
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
), 
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT
    s.s_name AS supplier_name,
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COALESCE(MAX(PSD.total_supply_cost), 0) AS max_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price
FROM supplier s
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN RankedOrders o ON s.s_suppkey = o.o_orderkey
LEFT JOIN PartSupplierDetails PSD ON s.s_suppkey = PSD.p_partkey
WHERE s.s_acctbal IS NOT NULL
GROUP BY s.s_name, n.n_name, r.r_name
HAVING AVG(o.o_totalprice) > (
    SELECT AVG(o_avg.o_totalprice)
    FROM RankedOrders o_avg
    WHERE o_avg.rank <= 10
)
ORDER BY supplier_count DESC, max_supply_cost DESC;
