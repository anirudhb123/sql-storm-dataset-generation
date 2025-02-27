WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
AvgOrderValue AS (
    SELECT c.c_custkey,
           AVG(o.o_totalprice) AS avg_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RecentOrders AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_orderdate,
           LEAD(o.o_orderdate) OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS next_orderdate
    FROM orders o
)
SELECT DISTINCT 
    p.p_partkey,
    p.p_name,
    ROUNDED((SUM(l.l_extendedprice * (1 - l.l_discount)) / NULLIF(SUM(l.l_quantity), 0)), 2) AS avg_price,
    CASE 
        WHEN r.rank <= 3 THEN 'Top Supplier'
        WHEN r.rank IS NULL THEN 'No Supplier'
        ELSE 'Other Supplier'
    END AS supplier_tier,
    CASE 
        WHEN ao.avg_totalprice > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_status
FROM lineitem l
LEFT JOIN part p ON l.l_partkey = p.p_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers r ON r.s_suppkey = ps.ps_suppkey AND r.rank <= 3
LEFT JOIN AvgOrderValue ao ON ao.c_custkey = (
    SELECT c.c_custkey
    FROM customer c 
    WHERE c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
)
LEFT JOIN RecentOrders ro ON ro.o_orderkey = l.l_orderkey
WHERE (l.l_returnflag = 'N')
  AND (l.l_discount BETWEEN 0.0 AND 0.1 OR p.p_container IS NOT NULL)
  AND (ro.next_orderdate IS NULL OR ro.o_orderdate < ro.next_orderdate)
GROUP BY p.p_partkey, p.p_name, r.rank, ao.avg_totalprice
HAVING AVG(l.l_quantity) > 0
ORDER BY avg_price DESC, p.p_name
LIMIT 50;
