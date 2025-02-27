WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate <='2023-01-01'
), SupplierStats AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_availability, 
           AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
), CustomerSegment AS (
    SELECT c.c_mktsegment, 
           COUNT(DISTINCT o.o_custkey) AS total_customers
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_mktsegment
)

SELECT p.p_name, 
       p.p_retailprice, 
       COALESCE(ss.total_availability, 0) AS supplier_availability, 
       COALESCE(cs.total_customers, 0) AS customer_count,
       CASE 
           WHEN ro.price_rank IS NOT NULL THEN 'Top Order'
           ELSE 'Regular Order'
       END AS order_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierStats ss ON ps.ps_suppkey = ss.s_suppkey
LEFT JOIN CustomerSegment cs ON cs.c_mktsegment = (
    SELECT c.c_mktsegment
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderkey IN (SELECT o_orderkey FROM RankedOrders WHERE price_rank = 1)
    LIMIT 1
)
LEFT JOIN RankedOrders ro ON EXISTS (
    SELECT 1 
    FROM RankedOrders
    WHERE ro.o_orderkey = (
        SELECT MAX(o_orderkey) 
        FROM orders 
        WHERE o_orderstatus = 'O'
    )
)
WHERE (p.p_retailprice > 100 OR ss.avg_account_balance IS NULL)
AND ps.ps_availqty IS NOT NULL
ORDER BY p.p_retailprice DESC, supplier_availability DESC;
