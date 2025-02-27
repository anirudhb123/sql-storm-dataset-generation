WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartStatistics AS (
    SELECT 
        p.p_partkey,
        p.p_name, 
        SUM(COALESCE(ps.ps_availqty, 0)) AS total_availqty,
        AVG(COALESCE(ps.ps_supplycost, 0)) AS avg_supplycost,
        SUM(CASE WHEN l.l_discount > 0 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_sales
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_availqty,
    ps.avg_supplycost,
    cs.total_orders,
    cs.total_spent,
    cs.last_order_date,
    rs.s_name AS top_supplier
FROM PartStatistics ps
FULL OUTER JOIN CustomerOrders cs ON cs.total_spent > 1000 AND ps.discounted_sales IS NOT NULL
LEFT JOIN RankedSuppliers rs ON rs.rank = 1 AND ps.p_partkey IN (SELECT ps_partkey FROM partsupp)
WHERE ps.total_availqty > 50
  AND (
        cs.last_order_date IS NOT NULL 
        OR cs.total_orders IS NULL
    )
ORDER BY ps.total_availqty DESC, cs.total_spent DESC
LIMIT 100;
