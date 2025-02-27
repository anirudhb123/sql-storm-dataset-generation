WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           1 AS order_level 
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 
           oh.order_level + 1 
    FROM orders o 
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
),
RankedLineItems AS (
    SELECT l.*, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
           SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS total_order_price
    FROM lineitem l
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment,
           COALESCE(SUM(ps.ps_supplycost * ps.ps_availqty), 0) AS total_cost,
           COUNT(DISTINCT ps.ps_partkey) AS num_parts
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    oh.order_level,
    l.rn,
    l.l_extendedprice,
    l.total_order_price,
    s.s_name,
    s.total_cost,
    CASE 
        WHEN s.total_cost IS NULL THEN 'No Cost'
        ELSE s.s_comment
    END AS supplier_comment,
    CASE 
        WHEN SUM(l.l_extendedprice) OVER (PARTITION BY o.o_orderkey) > 5000 
        THEN 'High Value' 
        ELSE 'Standard' 
    END AS order_value_category
FROM OrderHierarchy oh
JOIN orders o ON oh.o_orderkey = o.o_orderkey
LEFT JOIN RankedLineItems l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierDetails s ON l.l_suppkey = s.s_suppkey
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND (s.total_cost > 100000 OR s.total_cost IS NULL)
ORDER BY o.o_orderdate DESC, s.total_cost DESC;
