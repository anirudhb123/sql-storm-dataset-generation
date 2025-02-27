WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ts.total_value + SUM(ps.ps_supplycost * ps.ps_availqty)
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, ts.total_value
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
),
NationRegion AS (
    SELECT n.n_name AS nation_name, r.r_name AS region_name, COUNT(*) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_name, r.r_name
)
SELECT 
    COALESCE(tr.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    c_order.o_orderkey,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    AVG(li.l_discount) AS avg_discount,
    COUNT(DISTINCT li.l_orderkey) AS total_orders,
    CASE 
        WHEN SUM(li.l_quantity) IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    nr.nation_name,
    nr.region_name,
    nt.total_value AS supplier_value
FROM lineitem li
LEFT JOIN CustomerOrders c_order ON li.l_orderkey = c_order.o_orderkey
LEFT JOIN supplier tr ON li.l_suppkey = tr.s_suppkey
JOIN NationRegion nr ON tr.s_nationkey = nr.supplier_count
LEFT JOIN TopSuppliers nt ON tr.s_suppkey = nt.s_suppkey
WHERE li.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    tr.s_name, 
    c_order.c_name, 
    c_order.o_orderkey, 
    nr.nation_name, 
    nr.region_name, 
    nt.total_value
HAVING SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
ORDER BY total_sales DESC, c_order.o_orderkey ASC
LIMIT 100;
