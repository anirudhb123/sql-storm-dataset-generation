WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_name,
        c.c_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' 
      AND c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
SupplierRevenue AS (
    SELECT
        ps.ps_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
MaxRevenue AS (
    SELECT 
        s.s_suppkey,
        MAX(sr.supplier_revenue) AS max_supplier_revenue
    FROM supplier s
    LEFT JOIN SupplierRevenue sr ON s.s_suppkey = sr.ps_suppkey
    GROUP BY s.s_suppkey
)
SELECT 
    r.r_name,
    MAX(o.total_revenue) AS max_order_revenue,
    CONCAT_WS(' - ', c.c_name, COALESCE(r.r_name, 'Unknown Region')) AS customer_region_info,
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS return_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' AND o.o_orderdate < '2023-06-01' THEN 1 ELSE 0 END) AS fulfilled_orders,
    COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
FROM RankedOrders o
LEFT JOIN nation n ON o.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN MaxRevenue mr ON o.o_orderkey = mr.s_suppkey
LEFT JOIN supplier s ON s.s_suppkey = mr.s_suppkey
WHERE o.order_rank <= 10
GROUP BY r.r_name
HAVING MAX(o.total_revenue) > (SELECT AVG(total_revenue) FROM RankedOrders)
ORDER BY max_order_revenue DESC;
