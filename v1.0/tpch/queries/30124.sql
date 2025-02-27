WITH RECURSIVE SuppliersCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, level + 1
    FROM supplier s
    JOIN SuppliersCTE scte ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA') 
    WHERE s.s_acctbal > scte.s_acctbal
    AND level < 5
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    AND o.o_orderstatus IN ('O', 'F')
),
LineItemsSummary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY l.l_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(total_revenue) AS nation_revenue
    FROM nation n
    JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
    JOIN LineItemsSummary lis ON l.l_orderkey = lis.l_orderkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name, 
    p.p_brand,
    ns.n_name AS nation_name,
    SUM(ps.ps_availqty) AS total_available,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(COALESCE(c.c_acctbal, 0)) AS average_customer_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
LEFT JOIN nation ns ON c.c_nationkey = ns.n_nationkey
LEFT JOIN SuppliersCTE scte ON scte.s_suppkey = l.l_suppkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
AND ns.n_name IS NOT NULL
GROUP BY p.p_name, p.p_brand, ns.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_sales DESC, average_customer_balance DESC
LIMIT 100;