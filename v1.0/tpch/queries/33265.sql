WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 1 AS level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    UNION ALL
    SELECT oh.o_orderkey, o.o_orderdate, o.o_totalprice, level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON oh.o_orderkey = o.o_orderkey
    WHERE oh.level < 5
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
ProductSummary AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, SUM(ps.ps_availqty) AS total_available_qty,
           AVG(p.p_retailprice) AS avg_retail_price
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr
    HAVING SUM(ps.ps_availqty) > 0
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM SupplierDetails s 
    WHERE s.rank <= 3
)
SELECT 
    oh.o_orderkey,
    oh.o_orderdate,
    oh.o_totalprice,
    ps.p_name,
    ps.total_available_qty,
    COALESCE(ts.s_name, 'No Supplier') AS supplier_name,
    'Order total: ' || ROUND(oh.o_totalprice - COALESCE(ts.s_acctbal, 0), 2) AS adjusted_total
FROM 
    OrderHierarchy oh
LEFT JOIN 
    lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN 
    ProductSummary ps ON l.l_partkey = ps.p_partkey
LEFT JOIN 
    TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE 
    oh.o_totalprice > 1000 AND 
    ps.avg_retail_price IS NOT NULL
ORDER BY 
    oh.o_orderdate DESC, 
    adjusted_total DESC;