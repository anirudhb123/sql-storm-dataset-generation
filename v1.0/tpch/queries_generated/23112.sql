WITH RankedOrders AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS status_rank
    FROM orders
    WHERE o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierStats AS (
    SELECT s_nationkey, SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
           COUNT(DISTINCT s_suppkey) AS supplier_count,
           AVG(s_acctbal) AS avg_account_balance
    FROM supplier
    JOIN partsupp ON s_suppkey = ps_suppkey
    GROUP BY s_nationkey
),
HighValueCustomers AS (
    SELECT c_custkey, c_name, c_acctbal,
           RANK() OVER (ORDER BY c_acctbal DESC) AS customer_rank
    FROM customer
    WHERE c_acctbal IS NOT NULL AND c_mktsegment = 'HOBBIES'
),
OrderLineDetails AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_line_value
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_orderkey
    HAVING SUM(l_extendedprice * (1 - l_discount)) > 1000
)
SELECT r.o_orderkey, r.o_orderstatus, r.o_totalprice,
       COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
       s.supplier_count, s.total_supply_cost,
       ol.total_line_value,
       CASE 
           WHEN r.o_orderstatus = 'F' THEN 'Finished'
           WHEN r.o_orderstatus = 'P' AND r.status_rank <= 5 THEN 'Pending Top 5'
           ELSE 'Other' 
       END AS order_status_group
FROM RankedOrders r
LEFT JOIN HighValueCustomers c ON r.o_custkey = c.c_custkey
LEFT JOIN SupplierStats s ON s.s_nationkey = (SELECT n.n_nationkey 
                                                FROM nation n 
                                                WHERE n.n_name = 'UNITED STATES')
LEFT JOIN OrderLineDetails ol ON r.o_orderkey = ol.l_orderkey
WHERE r.status_rank BETWEEN 1 AND 10
AND r.o_totalprice IS NOT NULL
ORDER BY r.o_totalprice DESC, s.avg_account_balance ASC NULLS LAST;
