WITH ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           CASE 
               WHEN o.o_orderstatus = 'O' THEN 'Open'
               WHEN o.o_orderstatus = 'F' THEN 'Finished'
               ELSE 'Unknown'
           END AS status,
           o.o_orderdate,
           SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
    FROM orders o
    LEFT JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderstatus, o.o_orderdate
    HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 100000
),
nations_with_supplier_counts AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) as supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT n.n_name,
       COALESCE(r.total_cost, 0) AS total_supplier_cost,
       COALESCE(o.total_revenue, 0) AS total_order_revenue,
       ns.supplier_count,
       CASE 
           WHEN ns.supplier_count > 5 THEN 'Many Suppliers'
           WHEN ns.supplier_count BETWEEN 3 AND 5 THEN 'Moderate Suppliers'
           ELSE 'Few Suppliers'
       END AS supplier_category
FROM nations_with_supplier_counts ns
LEFT JOIN (
    SELECT n.n_name, SUM(r.total_cost) AS total_cost
    FROM ranked_suppliers r
    JOIN nation n ON r.n_nationkey = n.n_nationkey
    WHERE r.rank = 1
    GROUP BY n.n_name
) r ON ns.n_name = r.n_name
LEFT JOIN (
    SELECT DISTINCT no.o_orderkey, SUM(no.revenue) AS total_revenue
    FROM filtered_orders no
    GROUP BY no.o_orderkey
) o ON ns.n_name = o.o_orderkey
ORDER BY ns.supplier_count DESC, total_order_revenue DESC;
