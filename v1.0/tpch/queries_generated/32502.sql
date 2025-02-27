WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey AS nation_key, s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.n_nationkey, s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.nation_key
    WHERE s.s_acctbal < sh.s_acctbal * 0.9
),
RankedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierProductDetails AS (
    SELECT p.p_partkey, p.p_name, s.s_name AS supplier_name, ps.ps_availqty, ps.ps_supplycost,
           p.p_retailprice, (ps.ps_supplycost - p.p_retailprice) AS price_diff,
           COALESCE(NULLIF(s.s_comment, ''), 'No Comments') AS supplier_comment
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT R.total_price, SPD.p_partkey, SPD.p_name, SPD.supplier_name, SPD.ps_availqty,
       SPD.price_diff, S.level AS supplier_level
FROM RankedOrders R
JOIN SupplierProductDetails SPD ON SPD.p_partkey IN (
    SELECT p.p_partkey
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_totalprice > R.total_price
)
LEFT JOIN SupplierHierarchy S ON SPD.supplier_name = S.s_name
WHERE R.order_rank <= 5
ORDER BY R.total_price DESC, SPD.price_diff;
