WITH RecursiveSupplier AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) as rank
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
FilteredOrders AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice,
           CASE WHEN o_orderstatus = 'O' THEN 'Open'
                WHEN o_orderstatus = 'F' THEN 'Filled'
                ELSE 'Unknown' END AS status_desc,
           EXTRACT(YEAR FROM CURRENT_DATE) - EXTRACT(YEAR FROM o_orderdate) AS order_age
    FROM orders
    WHERE o_totalprice > 10000 AND o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
),
LineitemAggregates AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue,
           AVG(l_quantity) AS avg_quantity, COUNT(*) AS item_count
    FROM lineitem
    GROUP BY l_orderkey
),
NationsWithRegions AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, r.r_comment,
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_nationkey) AS nation_rank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT DISTINCT F.o_orderkey, F.o_totalprice, F.status_desc, 
       L.revenue, L.avg_quantity, L.item_count,
       COALESCE(S.s_name, 'No Supplier') AS supplier_name, 
       N.n_name AS nation_name,
       CASE WHEN L.item_count > 5 THEN 'High Item Count'
            WHEN L.item_count IS NULL THEN 'No Items'
            ELSE 'Standard Item Count' END AS item_count_desc
FROM FilteredOrders F
LEFT JOIN LineitemAggregates L ON F.o_orderkey = L.l_orderkey
LEFT JOIN RecursiveSupplier S ON S.rank <= 3 AND S.s_suppkey IN (
    SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (
        SELECT l_partkey FROM lineitem WHERE l_orderkey = F.o_orderkey
    )
)
RIGHT JOIN NationsWithRegions N ON N.n_nationkey = 
    (SELECT TOP 1 c_nationkey FROM customer WHERE c_custkey = F.o_custkey ORDER BY c_acctbal DESC)
WHERE (F.o_orderstatus = 'O' OR N.n_name NOT LIKE '%land%')
ORDER BY F.o_totalprice DESC NULLS LAST;
