WITH RECURSIVE CTE_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS recursion_level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 100.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, c.recursion_level + 1
    FROM supplier s
    JOIN CTE_Suppliers c ON s.s_nationkey = 
        (SELECT n.n_nationkey 
         FROM nation n 
         WHERE n.n_name = 'GERMANY'
         FETCH FIRST 1 ROW ONLY)
    WHERE c.recursion_level < 5
),
CTE_Orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
CTE_LineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
),
CTE_NationSales AS (
    SELECT n.n_name, SUM(li.total_sales) AS total_sales_by_nation
    FROM nation n
    LEFT JOIN CTE_LineItems li ON li.l_orderkey = 
        (SELECT o.o_orderkey 
         FROM orders o 
         WHERE o.o_custkey IN 
             (SELECT c.c_custkey 
              FROM customer c 
              WHERE c.c_nationkey = n.n_nationkey)
         FETCH FIRST 1 ROW ONLY)
    GROUP BY n.n_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(COALESCE(s.s_acctbal, 0)) AS avg_acct_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    MAX(o.o_totalprice) AS max_order_price,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'High'
        ELSE 'Low'
    END AS order_volume_category,
    STRING_AGG(DISTINCT n.n_name, ', ') FILTER (WHERE total_sales_by_nation > 10000) AS nations_with_high_sales
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN CTE_Suppliers s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CTE_Orders o ON o.o_orderkey = ps.ps_partkey
LEFT JOIN CTE_NationSales n ON n.n_name = s.s_name
GROUP BY p.p_partkey, p.p_name
HAVING SUM(ps.ps_availqty) > 0 AND (AVG(s.s_acctbal) IS NULL OR AVG(s.s_acctbal) > 50.00)
ORDER BY p.p_partkey;
