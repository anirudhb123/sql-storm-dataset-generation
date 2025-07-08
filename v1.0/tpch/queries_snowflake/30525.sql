WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = (
            SELECT n.n_nationkey 
            FROM nation n 
            WHERE n.n_name = 'USA'
        )
        LIMIT 1
    ) 
    WHERE o.o_orderstatus = 'O'
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    INNER JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > 100000
),
HighValueOrders AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY oh.order_level ORDER BY oh.o_totalprice DESC) AS rank
    FROM OrderHierarchy oh
    WHERE oh.o_totalprice > 5000
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    COALESCE(s.s_name, 'Unknown') AS supplier_name,
    SUM(hi.l_extendedprice) AS total_lineitem_value,
    COUNT(hi.l_orderkey) AS number_of_lineitems,
    CASE 
        WHEN hw.total_supplycost IS NOT NULL THEN 'High'
        ELSE 'Low'
    END AS supplier_rating
FROM HighValueOrders oh
LEFT JOIN lineitem hi ON oh.o_orderkey = hi.l_orderkey
LEFT JOIN TopSuppliers hw ON hi.l_suppkey = hw.ps_suppkey
LEFT JOIN supplier s ON hi.l_suppkey = s.s_suppkey
GROUP BY 
    oh.o_orderkey, 
    oh.o_orderdate, 
    supplier_name, 
    supplier_rating
HAVING 
    COUNT(hi.l_orderkey) > 5 
ORDER BY 
    total_lineitem_value DESC;
