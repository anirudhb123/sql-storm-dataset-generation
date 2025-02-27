WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM SupplierSummary s
    WHERE total_cost > (SELECT AVG(total_cost) FROM SupplierSummary)
),
RecentOrders AS (
    SELECT 
        l.o_orderkey,
        l.l_partkey,
        l.l_quantity,
        ROW_NUMBER() OVER (PARTITION BY l.o_orderkey ORDER BY l.l_receiptdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate > NOW() - INTERVAL '30 days'
),
NationSupplier AS (
    SELECT 
        n.n_name,
        SUM(CASE WHEN hs.s_suppkey IS NOT NULL THEN 1 ELSE 0 END) AS supplier_count,
        AVG(ss.total_cost) AS avg_supplier_cost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN HighValueSuppliers hs ON s.s_suppkey = hs.s_suppkey
    LEFT JOIN SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY n.n_name
)

SELECT 
    n.n_name,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    ROUND(COALESCE(ss.total_cost, 0) * 0.9, 2) AS adjusted_cost,
    c.c_name,
    c.total_spent,
    CASE 
        WHEN c.total_spent / NULLIF(c.order_count, 0) > 500 THEN 'High spender'
        WHEN c.total_spent IS NULL THEN 'No orders'
        ELSE 'Regular spender' 
    END AS customer_type
FROM nation n
JOIN NationSupplier ns ON n.n_name = ns.n_name
LEFT JOIN HighValueSuppliers s ON ns.supplier_count > 0 AND s.s_suppkey IN (SELECT hs.s_suppkey FROM hs)
LEFT JOIN CustomerOrders c ON n.n_nationkey = c.c_nationkey
ORDER BY adjusted_cost DESC, supplier_name ASC
FETCH FIRST 10 ROWS ONLY;
