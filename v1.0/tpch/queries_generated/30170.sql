WITH RECURSIVE SuppliersCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    JOIN SuppliersCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
),
OrderLineData AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS row_num
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CombinedData AS (
    SELECT 
        n.n_name,
        p.p_name,
        ps.ps_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN customer c ON s.s_nationkey = c.c_nationkey
    GROUP BY n.n_name, p.p_name, ps.ps_availqty
)
SELECT 
    cd.n_name,
    cd.p_name,
    cd.ps_availqty,
    cd.total_supplycost,
    CASE 
        WHEN cd.customer_count IS NULL THEN 'No Customers'
        ELSE CAST(cd.customer_count AS VARCHAR)
    END AS customer_info,
    COALESCE((SELECT MAX(total_amount) FROM OrderLineData WHERE row_num = 1), 0) AS max_order_amount,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers
FROM CombinedData cd
JOIN SuppliersCTE s ON cd.customer_count > 0
GROUP BY cd.n_name, cd.p_name, cd.ps_availqty, cd.total_supplycost, cd.customer_count
ORDER BY cd.n_name, cd.total_supplycost DESC;
