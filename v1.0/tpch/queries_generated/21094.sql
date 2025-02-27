WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_container,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 100
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'A%')
    GROUP BY c.c_custkey, c.c_name
),
Quantities AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    r.p_partkey AS top_part,
    r.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    coalesce(q.total_quantity, 0) AS order_quantity,
    coalesce(q.total_value, 0.00) AS order_value,
    CASE 
        WHEN coalesce(q.total_value, 0) = 0 THEN 'NO SALES'
        ELSE 'SOLD'
    END AS sales_status,
    SUM(CASE WHEN c.order_count > 5 THEN 1 ELSE 0 END) OVER () AS frequent_customers,
    MAX(s.total_revenue) OVER (PARTITION BY r.p_partkey) AS max_supplier_revenue
FROM RankedParts r
LEFT JOIN SupplierInfo s ON r.p_partkey = s.s_suppkey
LEFT JOIN CustomerOrders c ON c.order_count > 0
LEFT JOIN Quantities q ON q.l_orderkey = r.p_partkey
WHERE s.total_revenue IS NOT NULL OR c.total_spent IS NULL
ORDER BY r.p_partkey
FETCH FIRST 100 ROWS ONLY;
