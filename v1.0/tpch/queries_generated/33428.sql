WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS depth
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_nationkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
    HAVING SUM(ps.ps_availqty) > 1000
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 100
    GROUP BY c.c_custkey
),
CombinedSummary AS (
    SELECT 
        nh.n_name,
        COALESCE(ss.total_availability, 0) AS total_availability,
        COALESCE(cs.order_count, 0) AS order_count,
        COALESCE(cs.total_spent, 0.00) AS total_spent,
        ss.avg_acct_balance
    FROM NationHierarchy nh
    LEFT JOIN SupplierStats ss ON nh.n_nationkey = ss.s_nationkey
    LEFT JOIN CustomerOrderSummary cs ON nh.n_nationkey = cs.c_custkey
)
SELECT 
    n_name,
    total_availability,
    order_count,
    total_spent,
    avg_acct_balance,
    ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
FROM CombinedSummary
WHERE order_count >= 5
ORDER BY total_spent DESC;
