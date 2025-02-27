WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TopSupp AS (
    SELECT 
        r.r_regionkey, 
        r.r_name AS region_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN RankedSuppliers s ON n.n_nationkey = s.s_nationkey AND s.rnk <= 3
    GROUP BY r.r_regionkey, r.r_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS returned_price,
        COUNT(l.l_orderkey) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        od.o_orderkey,
        od.returned_price,
        od.line_item_count,
        CASE 
            WHEN od.returned_price > 1000 THEN 'High'
            WHEN od.returned_price BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS order_value_category
    FROM OrderDetails od
)
SELECT 
    rg.region_name, 
    COALESCE(s.s_name, 'No Supplier') AS supplier_name, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN h.order_value_category = 'High' THEN 1 ELSE 0 END) AS high_value_orders,
    AVG(COALESCE(od.returned_price, 0)) AS avg_returned_price,
    STRING_AGG(DISTINCT CONCAT('Order ', o.o_orderkey, ': ', COALESCE(NULLIF(h.order_value_category, 'Low'), 'N/A')), '; ') AS order_summary
FROM TopSupp rg
LEFT JOIN RankedSuppliers s ON rg.supplier_count > 0 AND s.rnk = 1
LEFT JOIN orders o ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
LEFT JOIN HighValueOrders h ON o.o_orderkey = h.o_orderkey
LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
WHERE (s.s_name IS NULL OR h.order_value_category = 'High')
GROUP BY rg.region_name, supplier_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_orders DESC, rg.region_name ASC;
