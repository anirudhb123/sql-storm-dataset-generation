WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' 
    AND o.o_orderdate < DATE '2024-01-01'
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
ComplexCoupling AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT CAST(NULLIF(CAST(SUBSTRING(c.c_name FROM 1 FOR 1) AS INTEGER), 0) AS INTEGER) 
                         FROM customer c WHERE c.c_acctbal IS NOT NULL)
    AND p.p_comment NOT LIKE '%obsolete%'
),
SubqueryMarketSegment AS (
    SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           c.c_mktsegment
    FROM lineitem l
    INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
    INNER JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus IN ('F', 'O')
    GROUP BY c.c_mktsegment
    HAVING COUNT(DISTINCT o.o_orderkey) > 10
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, 
       s.s_name, h.total_supplycost,
       p.p_name, p.price_rank,
       coalesce(m.total_revenue, 0) AS market_revenue
FROM RankedOrders r
LEFT JOIN HighValueSuppliers s ON r.o_orderkey % 10 = s.s_suppkey % 10
LEFT JOIN ComplexCoupling p ON r.o_orderkey = p.p_partkey
LEFT JOIN SubqueryMarketSegment m ON p.price_rank = m.total_revenue % 5
WHERE r.order_rank <= 5
AND (s.total_supplycost IS NOT NULL OR r.o_orderstatus IS NULL)
ORDER BY r.o_orderdate DESC, p.p_retailprice DESC;
