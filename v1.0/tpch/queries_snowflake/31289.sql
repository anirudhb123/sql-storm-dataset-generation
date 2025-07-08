WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplyChain sc ON sc.p_partkey = p.p_partkey
    WHERE ps.ps_availqty > sc.ps_availqty
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01'
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, SUM(ps.ps_availqty) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
    HAVING SUM(ps.ps_availqty) > 100
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, p.p_name, p.total_available, sc.s_name,
       CASE WHEN r.rank <= 5 THEN 'Top Seller' ELSE 'Other' END AS category
FROM RankedOrders r
LEFT JOIN FilteredParts p ON r.o_orderkey = p.p_partkey
LEFT JOIN SupplyChain sc ON p.p_partkey = sc.p_partkey
WHERE r.o_totalprice > 1000.00 OR p.total_available IS NULL
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC, p.p_name;