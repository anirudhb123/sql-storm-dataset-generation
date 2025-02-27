WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_orderstatus, 1 AS level
    FROM orders
    WHERE o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
AggregatedSales AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY p.p_partkey, p.p_name
),
SupplierInfo AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           s.s_comment, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment
),
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.total_cost,
           s.rank,
           n.n_name
    FROM SupplierInfo s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.rank <= 3
),
FinalResults AS (
    SELECT oh.o_orderkey, 
           oh.o_orderdate, 
           a.total_sales,
           ts.s_name,
           ts.n_name
    FROM OrderHierarchy oh
    LEFT JOIN AggregatedSales a ON oh.o_orderkey = a.p_partkey
    LEFT JOIN TopSuppliers ts ON ts.s_suppkey = (SELECT ps.ps_suppkey 
                                                  FROM partsupp ps 
                                                  JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                                  WHERE l.l_orderkey = oh.o_orderkey 
                                                  LIMIT 1)
)
SELECT DISTINCT fr.o_orderkey, 
                fr.o_orderdate, 
                COALESCE(fr.total_sales, 0) AS total_sales,
                COALESCE(fr.s_name, 'Unknown Supplier') AS supplier_name,
                COALESCE(fr.n_name, 'Unknown Nation') AS nation_name
FROM FinalResults fr
WHERE fr.total_sales > 5000 OR fr.supplier_name IS NULL
ORDER BY fr.o_orderdate DESC, fr.total_sales DESC;
