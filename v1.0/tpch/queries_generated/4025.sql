WITH SupplierStats AS (
    SELECT s_nationkey, 
           COUNT(DISTINCT s_suppkey) AS total_suppliers, 
           SUM(s_acctbal) AS total_account_balance
    FROM supplier
    WHERE s_acctbal > 1000.00
    GROUP BY s_nationkey
),
PartStats AS (
    SELECT ps_partkey,
           SUM(ps_availqty) AS total_available_qty,
           AVG(ps_supplycost) AS avg_supply_cost
    FROM partsupp
    GROUP BY ps_partkey
),
OrderStats AS (
    SELECT o_custkey,
           SUM(o_totalprice) AS total_orders_value,
           COUNT(o_orderkey) AS order_count
    FROM orders
    WHERE o_orderstatus = 'O'
    GROUP BY o_custkey
),
LineItemStats AS (
    SELECT l_orderkey,
           COUNT(*) AS line_item_count,
           SUM(l_extendedprice * (1 - l_discount)) AS total_line_item_value
    FROM lineitem
    WHERE l_shipdate >= '2023-01-01'
    GROUP BY l_orderkey
)
SELECT n.n_name,
       r.r_name,
       COALESCE(S.total_suppliers, 0) AS number_of_suppliers,
       COALESCE(P.total_available_qty, 0) AS available_quantity,
       (CASE 
            WHEN O.total_orders_value IS NULL THEN 0 
            ELSE O.total_orders_value 
        END) AS order_value,
       (CASE 
            WHEN L.line_item_count IS NULL THEN 0 
            ELSE L.line_item_count 
        END) AS line_item_count,
       (S.total_account_balance + (P.avg_supply_cost * P.total_available_qty)) AS supplier_and_part_value
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierStats S ON n.n_nationkey = S.s_nationkey
LEFT JOIN PartStats P ON P.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_container IS NOT NULL)
LEFT JOIN OrderStats O ON O.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
LEFT JOIN LineItemStats L ON L.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = O.o_custkey)
ORDER BY n.n_name, r.r_name;
