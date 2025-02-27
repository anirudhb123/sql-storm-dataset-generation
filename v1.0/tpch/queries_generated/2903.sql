WITH TotalSupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerRanking AS (
    SELECT c.c_custkey, c.c_name, RANK() OVER (ORDER BY SUM(ro.order_total) DESC) AS rank
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT c.c_custkey, c.c_name, COALESCE(t.total_cost, 0) AS total_supplier_cost, cr.rank
FROM customer c
LEFT JOIN TotalSupplierCost t ON c.c_custkey = (SELECT cs.c_custkey 
                                                  FROM customer cs 
                                                  JOIN orders o ON cs.c_custkey = o.o_custkey 
                                                  JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                                  WHERE l.l_partkey = t.ps_partkey 
                                                  LIMIT 1)
LEFT JOIN CustomerRanking cr ON c.c_custkey = cr.c_custkey
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
ORDER BY cr.rank, c.c_name;
