
WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 AS depth
    FROM nation n
    WHERE n.n_nationkey = (SELECT MIN(n2.n_nationkey) FROM nation n2)

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_regionkey
    WHERE nh.depth < 5
),

TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
),

OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N' AND l.l_commitdate < l.l_shipdate
    GROUP BY o.o_orderkey, o.o_totalprice
),

SupplierOrders AS (
    SELECT s.s_name, SUM(od.net_sales) AS supplier_sales
    FROM TopSuppliers s
    LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
    LEFT JOIN OrderDetails od ON od.o_orderkey = l.l_orderkey
    GROUP BY s.s_name
)

SELECT n.n_name, COALESCE(SUM(so.supplier_sales), 0) AS total_sales_from_suppliers
FROM nation n
LEFT JOIN SupplierOrders so ON n.n_nationkey = (
    SELECT s.s_nationkey
    FROM supplier s
    WHERE s.s_name LIKE CONCAT('%', n.n_name, '%')
    LIMIT 1
)
GROUP BY n.n_name
HAVING COALESCE(SUM(so.supplier_sales), 0) > (SELECT AVG(total_sales_from_suppliers) FROM (
    SELECT COALESCE(SUM(so.supplier_sales), 0) AS total_sales_from_suppliers
    FROM nation n2
    LEFT JOIN SupplierOrders so ON n2.n_nationkey = (
        SELECT s.s_nationkey
        FROM supplier s
        WHERE s.s_name LIKE CONCAT('%', n2.n_name, '%')
        LIMIT 1
    )
    GROUP BY n2.n_name
) AS avg_sales)
ORDER BY total_sales_from_suppliers DESC
LIMIT 10;
