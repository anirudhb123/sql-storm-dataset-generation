
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        1 AS depth
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        oh.depth + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.depth < 5
),
AggregateData AS (
    SELECT
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
      AND l.l_discount BETWEEN 0.05 AND 0.1
    GROUP BY c.c_name
),
RankedCustomers AS (
    SELECT 
        c.c_name,
        a.total_revenue,
        a.order_count,
        RANK() OVER (ORDER BY a.total_revenue DESC) AS revenue_rank
    FROM AggregateData a
    JOIN customer c ON a.c_name = c.c_name
)
SELECT
    r.r_name,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COALESCE(SUM(od.total_revenue), 0) AS total_customer_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN part p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps
                                      WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN RankedCustomers od ON s.s_name = od.c_name
WHERE r.r_name LIKE 'N%'
GROUP BY r.r_name
HAVING AVG(s.s_acctbal) < (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY part_count DESC, total_customer_revenue DESC;
