WITH RankedSuppliers AS (
    SELECT s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
LineItemSummary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(*) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate IS NOT NULL
    GROUP BY l.l_orderkey
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           p.p_retailprice, 
           (CASE 
               WHEN ps.ps_availqty IS NULL THEN 'Unavailable'
               WHEN ps.ps_availqty < 50 THEN 'Low Stock'
               ELSE 'In Stock' 
            END) AS inventory_status
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_container LIKE '%BOX%'
),
ComplexJoin AS (
    SELECT r.r_name, n.n_name, ps.p_partkey, ps.inventory_status,
           ns.nation_sales, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM Region r
    JOIN Nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN (
        SELECT ns.n_nationkey, SUM(l.total_revenue) AS nation_sales
        FROM RecentOrders o
        JOIN LineItemSummary l ON o.o_orderkey = l.l_orderkey
        JOIN Customer c ON o.o_custkey = c.c_custkey
        JOIN Nation ns ON c.c_nationkey = ns.n_nationkey
        GROUP BY ns.n_nationkey
    ) ns ON ns.n_nationkey = n.n_nationkey
    JOIN PartSupplierInfo ps ON ps.p_partkey IN (
        SELECT ps_partkey 
        FROM partsupp 
        WHERE ps_supplycost > (
            SELECT AVG(ps_supplycost) FROM partsupp
        )
    )
    GROUP BY r.r_name, n.n_name, ps.p_partkey, ps.inventory_status, ns.nation_sales
)
SELECT DISTINCT c.c_name, c.c_acctbal, o.o_orderkey, l.total_items, ps.total_revenue,
       CASE WHEN ps.inventory_status = 'Unavailable' THEN 'Order Elsewhere'
            ELSE 'Available for Order' END AS order_status
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN LineItemSummary l ON o.o_orderkey = l.l_orderkey
JOIN ComplexJoin ps ON ps.p_partkey IN (
    SELECT ps_partkey
    FROM partsupp
    WHERE ps_availqty > (SELECT COUNT(*) FROM supplier) * 0.1
)
WHERE c.c_acctbal IS NOT NULL AND o.o_totalprice > 1000
ORDER BY c.c_name, o.o_orderdate DESC
OFFSET 10 ROWS FETCH NEXT 5 ROWS ONLY;
