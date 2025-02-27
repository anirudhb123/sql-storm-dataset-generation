WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE n.n_comment IS NOT NULL
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost * (1 - (CASE WHEN l.l_discount IS NULL THEN 0 ELSE l.l_discount END)) AS effective_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey AND l.l_quantity < 10
    WHERE p.p_size BETWEEN 10 AND 100 AND p.p_retailprice IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(SUM(o_totalprice)) FROM orders GROUP BY o_custkey) 
       AND order_count > 5
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM RankedSuppliers rs
    WHERE rs.supplier_rank = 1
)
SELECT 
    c.c_name,
    pd.p_name,
    hvs.s_name,
    pd.effective_cost
FROM PartDetails pd
JOIN lineitem l ON pd.p_partkey = l.l_partkey
JOIN HighValueSuppliers hvs ON l.l_suppkey = hvs.s_suppkey
JOIN CustomerOrders c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE pd.cost_rank <= 5
  AND pd.effective_cost IS NOT NULL
  AND hvs.s_name NOT LIKE '%unknown%'
ORDER BY c.c_name, pd.effective_cost DESC;
