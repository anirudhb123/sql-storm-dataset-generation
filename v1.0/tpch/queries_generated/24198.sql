WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT oo.o_orderkey) AS order_count,
        SUM(oo.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN RankedOrders oo ON c.c_custkey = oo.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationSupplierStats AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acct_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_spent, 0) AS total_spent,
    ns.n_name AS nation_name,
    ns.supplier_count,
    ns.total_acct_balance
FROM CustomerOrders co
FULL OUTER JOIN nation n ON co.c_custkey = n.n_nationkey
JOIN NationSupplierStats ns ON n.n_name = ns.n_name
WHERE (co.total_spent IS NULL OR co.total_spent > 1000.00)
    AND (length(co.customer_name) > 5 OR c.c_custkey IS NULL)
ORDER BY ns.total_acct_balance DESC, co.total_spent DESC
LIMIT 100 OFFSET 10;

WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'F'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
    WHERE o.o_orderstatus = 'P' AND oh.order_level < 5
)
SELECT COUNT(*) 
FROM OrderHierarchy
WHERE order_level = 3;
