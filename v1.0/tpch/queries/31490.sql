
WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_totalprice, o_orderdate, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O' AND o_totalprice > (SELECT AVG(o_totalprice) FROM orders WHERE o_orderdate >= '1997-01-01')
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name = 'Acme Corp')
    WHERE o.o_orderdate < '1997-01-01' AND oh.level < 5
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01' 
    AND l.l_returnflag = 'N'
    GROUP BY l.l_orderkey, l.l_partkey
),
SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, SUM(pl.total_revenue) AS total_supplier_revenue, 
           RANK() OVER (ORDER BY SUM(pl.total_revenue) DESC) AS revenue_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN FilteredLineItems pl ON ps.ps_partkey = pl.l_partkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM SupplierRevenue s
    WHERE s.revenue_rank <= 10
)
SELECT 
    oh.o_orderkey, 
    oh.o_totalprice, 
    oh.o_orderdate, 
    ts.s_name AS supplier_name,
    CASE 
        WHEN oh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) THEN 'Above Average'
        ELSE 'Below Average' 
    END AS price_category,
    COALESCE(ts.s_name, 'No Supplier') AS final_supplier_name
FROM OrderHierarchy oh
LEFT JOIN TopSuppliers ts ON oh.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = oh.o_orderkey LIMIT 1)
ORDER BY oh.o_orderdate DESC, oh.o_orderkey ASC;
