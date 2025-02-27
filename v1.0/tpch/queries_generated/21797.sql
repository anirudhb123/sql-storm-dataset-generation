WITH RECURSIVE CTE_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey) AS supplier_parts_count
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           c.supplier_parts_count + (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
    FROM supplier s
    JOIN CTE_Suppliers c ON s.s_suppkey = c.s_suppkey + 1
    WHERE c.supplier_parts_count < 10
),
CTE_Orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
),
Enhanced_LineItems AS (
    SELECT l.*, 
           (CASE 
                WHEN l.l_discount = 0 THEN l.l_extendedprice 
                ELSE l.l_extendedprice * (1 - l.l_discount) 
            END) AS net_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_order
    FROM lineitem l
    WHERE l.l_quantity > 0
),
Final_Result AS (
    SELECT n.n_name, SUM(el.net_price) AS total_net_price, AVG(s.s_acctbal) AS avg_supplier_acctbal,
           COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN CTE_Suppliers cs ON s.s_suppkey = cs.s_suppkey
    JOIN Enhanced_LineItems el ON s.s_suppkey = el.l_suppkey
    JOIN CTE_Orders o ON el.l_orderkey = o.o_orderkey
    WHERE n.n_name IS NOT NULL AND el.l_returnflag = 'R'
    GROUP BY n.n_name
    HAVING COUNT(*) > 5 OR MAX(el.l_discount) IS NULL
)
SELECT r.r_name, COALESCE(fr.total_net_price, 0) AS total_net_sales, 
       COALESCE(fr.avg_supplier_acctbal, 0) AS avg_supplier_balance
FROM region r
LEFT JOIN Final_Result fr ON r.r_name = fr.n_name
WHERE r.r_regionkey IN (SELECT DISTINCT n.n_regionkey FROM nation n WHERE n.n_name LIKE 'A%')
ORDER BY total_net_sales DESC, avg_supplier_balance ASC;
