WITH RECURSIVE CTE_Nation AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 1 AS depth
    FROM nation
    WHERE n_nationkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, c.depth + 1
    FROM nation n
    JOIN CTE_Nation c ON n.n_regionkey = c.n_nationkey
    WHERE c.depth < 10
),
CTE_SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(p.ps_supplycost * p.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(p.ps_supplycost * p.ps_availqty) DESC) AS rn
    FROM supplier s
    JOIN partsupp p ON s.s_suppkey = p.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank,
        (SELECT COUNT(*)
         FROM lineitem l 
         WHERE l.l_orderkey = o.o_orderkey AND l.l_returnflag = 'R') AS return_count
    FROM orders o
),
SelectedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
SELECT 
    n.n_name AS nation,
    s.s_name AS supplier,
    ss.total_cost,
    c.c_name AS customer,
    oc.o_totalprice,
    COALESCE(o.return_count, 0) AS return_count,
    CASE 
        WHEN oc.price_rank > 10 THEN 'Low spender'
        WHEN oc.price_rank BETWEEN 5 AND 10 THEN 'Average spender'
        ELSE 'High spender'
    END AS spending_category
FROM CTE_Nation n
FULL OUTER JOIN CTE_SupplierSummary ss ON n.n_nationkey = ss.s_suppkey
LEFT JOIN SelectedCustomers c ON n.n_nationkey = c.c_custkey
LEFT JOIN OrderStats oc ON oc.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderkey < oc.o_orderkey)
WHERE n.depth IS NOT NULL
  AND (ss.part_count > 5 OR ss.total_cost IS NOT NULL)
ORDER BY n.n_name, ss.total_cost DESC, spending_category;
