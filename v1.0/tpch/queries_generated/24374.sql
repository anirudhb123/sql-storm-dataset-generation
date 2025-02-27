WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM supplier s
),
AggregatedStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        AVG(COALESCE(l.l_quantity, 0)) AS avg_line_quantity,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
CustomerOrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(o.o_totalprice) AS total_purchase
    FROM orders o
    GROUP BY o.o_custkey
),
FinalOutput AS (
    SELECT 
        a.n_name,
        sr.s_name AS top_supplier,
        sr.s_acctbal,
        a.total_avail_qty,
        a.avg_line_quantity,
        a.unique_customers,
        COALESCE(cos.total_purchase, 0) AS total_customer_purchase
    FROM AggregatedStats a
    LEFT JOIN RankedSuppliers sr ON sr.s_nationkey = a.n_nationkey AND sr.rank_by_balance = 1
    LEFT JOIN CustomerOrderSummary cos ON cos.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = a.n_nationkey 
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
)
SELECT 
    n.n_name,
    COALESCE(avg_line_quantity, 0) AS avg_qty_per_line,
    CASE 
        WHEN total_avail_qty > 1000 THEN 'High Availability'
        WHEN total_avail_qty BETWEEN 500 AND 1000 THEN 'Medium Availability'
        ELSE 'Low Availability'
    END AS availability_status,
    CASE   
        WHEN total_customer_purchase IS NULL THEN 'No Purchases'
        ELSE 'Purchases Made'
    END AS purchase_status,
    CONCAT('Nation: ', n.n_name, ' | ', 'Availability: ', availability_status) AS narrative
FROM FinalOutput n
ORDER BY n.n_name;
