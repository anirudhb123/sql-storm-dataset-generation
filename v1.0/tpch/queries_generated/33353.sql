WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal BETWEEN 20000 AND 50000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(od.total_revenue) AS customer_total_revenue,
        COUNT(od.o_orderkey) AS order_count,
        STRING_AGG(od.o_orderdate::text, ', ' ORDER BY od.o_orderdate) AS order_dates
    FROM customer c
    LEFT JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_supply_cost,
    STRING_AGG(DISTINCT n.n_name, ', ') AS supplier_nations,
    AVG(cr.customer_total_revenue) AS avg_customer_revenue,
    MAX(cr.order_count) AS max_order_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN vendor v ON v.v_suppkey = ps.ps_suppkey
LEFT JOIN nation n ON v.v_nationkey = n.n_nationkey
LEFT JOIN CustomerRevenue cr ON cr.c_custkey = ps.ps_suppkey
WHERE p.p_retailprice > 100
AND (ps.ps_availqty IS NOT NULL OR p.p_container = 'BOX') 
GROUP BY p.p_partkey, p.p_name
HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
ORDER BY avg_customer_revenue DESC, total_supply_cost ASC
LIMIT 50;
