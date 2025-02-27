WITH RECURSIVE SuppliersHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SuppliersHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY o.o_custkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        os.total_revenue,
        RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM customer c
    JOIN OrderSummary os ON c.c_custkey = os.o_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    supplier_info.s_name,
    customers.c_name AS top_customer_name,
    customers.total_revenue,
    CASE 
        WHEN customers.total_revenue IS NULL THEN 'Unknown Customer'
        ELSE customers.top_customer_name 
    END AS final_customer_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_info ON ps.ps_suppkey = supplier_info.s_suppkey
FULL OUTER JOIN TopCustomers customers ON ps.ps_availqty = customers.order_count
WHERE p.p_size > 10
ORDER BY customers.total_revenue DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
