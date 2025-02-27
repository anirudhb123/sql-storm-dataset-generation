WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON oh.o_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND oh.level < 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_cost DESC
    LIMIT 10
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_discount, l.l_extendedprice, 
           CASE 
               WHEN l.l_discount > 0.05 THEN 'High Discount'
               ELSE 'Low Discount'
           END AS discount_category
    FROM lineitem l
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
),
CustomerRegion AS (
    SELECT c.c_custkey, c.c_name, r.r_name, c.c_acctbal
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
)
SELECT 
    ch.o_orderkey, 
    ch.o_orderdate, 
    lr.l_discount, 
    lr.discount_category, 
    cr.r_name AS customer_region,
    ts.s_name AS top_supplier,
    SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY ch.o_orderkey) AS net_price
FROM OrderHierarchy ch
JOIN FilteredLineItems lr ON ch.o_orderkey = lr.l_orderkey
LEFT JOIN CustomerRegion cr ON cr.c_custkey = ch.o_orderkey
LEFT JOIN TopSuppliers ts ON ts.total_cost > 1000
WHERE ch.o_totalprice > 5000
GROUP BY ch.o_orderkey, ch.o_orderdate, lr.l_discount, lr.discount_category, cr.r_name, ts.s_name
ORDER BY net_price DESC;
