WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderStats AS (
    SELECT o.o_custkey, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_custkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationSupplierCount AS (
    SELECT n.n_name AS nation_name, 
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n 
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name, 
    ds.s_name, 
    os.order_count, 
    os.total_spent,
    COALESCE(nsc.supplier_count, 0) AS supplier_count,
    CASE 
        WHEN os.total_spent > 10000 THEN 'High Value'
        WHEN os.total_spent BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    STRING_AGG(sh.s_name, ', ') AS related_suppliers
FROM PartDetails p
LEFT JOIN OrderStats os ON os.o_custkey = (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_acctbal > 5000.00 AND c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = (
            CASE 
                WHEN os.total_spent > 5000 THEN 'USA'
                ELSE 'Other'
            END
        )
    )
)
LEFT JOIN supplier ds ON ds.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN NationSupplierCount nsc ON nsc.nation_name = (
    SELECT n.n_name FROM nation n WHERE n.n_nationkey = ds.s_nationkey
)
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = ds.s_nationkey
WHERE p.revenue_rank <= 10
GROUP BY p.p_name, ds.s_name, os.order_count, os.total_spent, nsc.supplier_count
HAVING COUNT(ds.s_suppkey) > 1
ORDER BY os.total_spent DESC;
