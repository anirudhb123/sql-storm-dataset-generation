WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    JOIN SupplierCTE sc ON s.s_nationkey = sc.s_nationkey
    WHERE s.s_acctbal < sc.s_acctbal
),
TopNations AS (
    SELECT n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
    HAVING SUM(s.s_acctbal) > 5000
),
LineItemSummary AS (
    SELECT l.l_orderkey, COUNT(l.l_partkey) AS total_items, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM lineitem l
    GROUP BY l.l_orderkey
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM orders o
    JOIN LineItemSummary lis ON o.o_orderkey = lis.l_orderkey
    WHERE o.o_totalprice > 3000 AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(lis.total_price) AS total_order_value,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(lis.total_price) DESC) AS rank
FROM 
    TopNations tn
JOIN 
    nation n ON tn.n_name = n.n_name
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
JOIN 
    FilteredOrders fo ON fo.o_orderkey = c.c_custkey
JOIN 
    LineItemSummary lis ON fo.o_orderkey = lis.l_orderkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5 OR AVG(s.s_acctbal) IS NULL
ORDER BY 
    total_order_value DESC;