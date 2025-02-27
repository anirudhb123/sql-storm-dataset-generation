WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           o.o_totalprice, 
           o.o_orderdate, 
           o.o_orderpriority,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierAvailability AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_available
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
TopParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice,
           s_total.total_available,
           ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS popularity_rank
    FROM part p
    LEFT JOIN SupplierAvailability s_total ON p.p_partkey = s_total.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)
SELECT 
    c.c_name, 
    c.c_acctbal, 
    o.o_orderkey, 
    o.o_orderstatus, 
    o.o_totalprice, 
    tp.p_name, 
    tp.total_available 
FROM customer c 
JOIN orders o ON c.c_custkey = o.o_custkey
FULL OUTER JOIN TopParts tp ON tp.popularity_rank <= 10
WHERE 
    (o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL)
    AND (c.c_acctbal > 1000 OR (c.c_acctbal IS NULL AND c.c_name LIKE '%Inc%'))
    AND tp.total_available IS NOT NULL
ORDER BY o.o_totalprice DESC, c.c_name ASC;
