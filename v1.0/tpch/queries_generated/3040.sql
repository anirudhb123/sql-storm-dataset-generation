WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS average_account_balance,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    r.r_name AS region_name,
    cs.total_orders,
    cs.total_spent,
    ss.supplier_count,
    ss.average_account_balance,
    ss.total_supply_value,
    ro.order_rank,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 10000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM part p
LEFT JOIN SupplierStats ss ON p.p_partkey = ss.ps_partkey
JOIN nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.ps_partkey LIMIT 1)
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerSummary cs ON cs.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey LIMIT 1)
LEFT JOIN RankedOrders ro ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    p.p_retailprice > 50 AND 
    ss.supplier_count > 5 OR 
    cs.total_orders IS NULL
ORDER BY 
    r.r_name, 
    p.p_name;
