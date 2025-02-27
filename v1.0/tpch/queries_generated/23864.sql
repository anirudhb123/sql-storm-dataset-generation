WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01'
      AND o.o_orderdate < DATE '1997-01-01'
),
SuppliersWithLowStock AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, 
           SUM(ps.ps_availqty) as total_available
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) < 100
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ARRAY_AGG(o.o_orderkey) as orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal < 500
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT R.o_orderkey, R.o_totalprice, COALESCE(C.c_name, 'Unknown Customer') as CustomerName,
       S.s_name as SupplierName, R.o_orderdate,
       CASE 
           WHEN R.order_rank = 1 THEN 'Top Order'
           ELSE 'Regular Order'
       END as order_type,
       CASE 
           WHEN L.l_discount IS NULL THEN 0
           ELSE L.l_discount
       END as AppliedDiscount,
       (SELECT AVG(l_extendedprice * (1 - L.l_discount)) 
        FROM lineitem L WHERE L.l_orderkey = R.o_orderkey) as AverageExtendedPrice
FROM RankedOrders R
LEFT JOIN CustomerOrders C ON R.o_custkey = C.c_custkey
LEFT JOIN SuppliersWithLowStock S ON S.ps_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = R.o_orderkey
)
WHERE R.o_totalprice BETWEEN 1000 AND 5000
  AND R.o_orderstatus IN ('O', 'F')
  AND (R.o_orderdate IS NOT NULL OR S.s_name IS NOT NULL)
ORDER BY R.o_totalprice DESC, R.o_orderdate ASC
LIMIT 50;
