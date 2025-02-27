WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, 1 AS level 
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, oh.level + 1 
    FROM orders o 
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > (SELECT MAX(o2.o_orderdate) FROM orders o2 WHERE o2.o_orderkey = oh.o_orderkey) 
    AND oh.level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost 
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > 100
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS row_num
    FROM lineitem l
    WHERE l.l_discount > 0.1 AND l.l_tax < 0.05
),
TotalLineItemValue AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    oh.o_orderkey,
    oh.o_totalprice,
    oh.o_orderdate,
    sd.s_name,
    fl.l_partkey,
    fl.total_value,
    COALESCE(ROW_NUMBER() OVER (PARTITION BY oh.o_orderkey ORDER BY oh.o_orderdate DESC), 0) AS rank_order,
    CASE 
        WHEN oh.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_category,
    r.r_name AS region_name
FROM OrderHierarchy oh
LEFT JOIN SupplierDetails sd ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (SELECT fl.l_partkey FROM FilteredLineItems fl)
)
LEFT JOIN TotalLineItemValue tl ON tl.l_orderkey = oh.o_orderkey
JOIN nation n ON n.n_nationkey = 
    (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = oh.o_custkey)
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE sd.total_supply_cost IS NOT NULL
ORDER BY oh.o_orderdate DESC, sd.total_supply_cost DESC;
