WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey + 1
),
SupplierCosts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(sc.total_cost), 0) AS supplier_cost,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN region r ON s.s_nationkey = r.r_regionkey
LEFT JOIN SupplierCosts sc ON ps.ps_partkey = sc.ps_partkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
AND l.l_returnflag = 'N'
GROUP BY p.p_name, r.r_regionkey
HAVING revenue > (SELECT AVG(total_spent) FROM CustomerStats)
ORDER BY revenue_rank;
