WITH RECURSIVE CustomerOrderCounts AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierStock AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_stock
    FROM partsupp ps
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_discount,
           CASE 
               WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount)
               ELSE l.l_extendedprice
           END AS effective_price,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS line_num
    FROM lineitem l
    WHERE l.l_shipdate > '2023-01-01' AND l.l_returnflag = 'N'
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, co.order_count, ROW_NUMBER() OVER (ORDER BY co.order_count DESC) AS rank
    FROM CustomerOrderCounts co
    JOIN customer c ON c.c_custkey = co.c_custkey
    WHERE co.order_count > (SELECT AVG(order_count) FROM CustomerOrderCounts)
)
SELECT DISTINCT 
    p.p_partkey, p.p_name,
    SUM(l.effective_price) AS total_sales,
    COUNT(DISTINCT li.l_orderkey) AS num_orders,
    COALESCE(MAX(s.total_stock), 0) AS max_stock,
    CASE 
        WHEN r.r_name IN ('ASIA', 'EUROPE') THEN 'International'
        ELSE 'Domestic'
    END AS market_type
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN LineItemDetails li ON l.l_orderkey = li.l_orderkey
LEFT JOIN SupplierStock s ON l.l_partkey = s.ps_partkey
JOIN nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = li.l_orderkey) 
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice BETWEEN 50 AND 500
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING SUM(CASE WHEN l.l_discount > 0 THEN 1 ELSE 0 END) > 5
ORDER BY total_sales DESC
LIMIT 10;
