WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) as supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_orderstatus) AS order_statuses
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    p.p_name,
    ps.ps_availqty,
    COALESCE(RS.s_name, 'No Supplier') AS supplier_name,
    COS(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice ELSE 0 END)) AS anomaly_score,
    SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice ELSE 0 END) AS discounted_sales,
    DC.discount_value,
    COUNT(DISTINCT COALESCE(c.c_custkey, -1)) AS unique_customers,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS price_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedSuppliers RS ON ps.ps_suppkey = RS.s_suppkey AND RS.supplier_rank <= 3
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN CustomerOrderStats C ON C.total_orders > 5
LEFT JOIN (
    SELECT 
        c.c_custkey,
        MAX(o.o_totalprice * (1 - l.l_discount)) AS discount_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount IS NOT NULL
    GROUP BY c.c_custkey
) DC ON C.c_custkey = DC.c_custkey
WHERE p.p_retailprice BETWEEN 10 AND 500
  AND (C.total_spent IS NULL OR C.total_spent > 1000)
GROUP BY p.p_name, ps.ps_availqty, RS.s_name, DC.discount_value
HAVING COUNT(DISTINCT l.l_orderkey) FILTER (WHERE l.l_shipmode = 'TRUCK') > 5
ORDER BY anomaly_score DESC, unique_customers ASC
LIMIT 50;
