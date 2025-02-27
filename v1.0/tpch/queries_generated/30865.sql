WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey AS supplier_key, 
           s.s_name AS supplier_name, 
           s.s_acctbal AS account_balance, 
           s.s_nationkey AS nation_key, 
           1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey,
           s.s_name,
           s.s_acctbal,
           s.s_nationkey,
           sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.nation_key
    WHERE sh.hierarchy_level < 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_linenumber) AS num_items,
        o.o_orderstatus,
        o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_orderdate
),
CustomerRanked AS (
    SELECT
        c.c_custkey,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acct_rank,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
)
SELECT
    sh.supplier_key,
    sh.supplier_name,
    cr.total_spent,
    cr.acct_rank,
    os.total_price,
    os.num_items,
    CASE 
        WHEN cr.acct_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_classification
FROM SupplierHierarchy sh
LEFT JOIN CustomerRanked cr ON sh.nation_key = cr.c_custkey
LEFT JOIN OrderSummary os ON cr.c_custkey = os.o_orderkey
WHERE os.total_price IS NOT NULL OR cr.total_spent IS NOT NULL
ORDER BY sh.hierarchy_level, cr.total_spent DESC;
