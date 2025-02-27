WITH RECURSIVE PartSizes AS (
    SELECT p_size, COUNT(*) AS part_count
    FROM part
    GROUP BY p_size
    UNION ALL
    SELECT p_size + 1, part_count
    FROM PartSizes
    WHERE p_size + 1 <= (SELECT MAX(p_size) FROM part)
),
CustomerSummary AS (
    SELECT c_nationkey, SUM(c_acctbal) AS total_acct_balance, COUNT(*) AS customer_count
    FROM customer
    GROUP BY c_nationkey
),
OrderSummary AS (
    SELECT o_custkey, SUM(o_totalprice) AS total_order_value
    FROM orders
    WHERE o_orderstatus = 'O'
    GROUP BY o_custkey
),
SupplierDetails AS (
    SELECT s_nationkey, AVG(s_acctbal) AS avg_account_balance, 
           COUNT(DISTINCT s_suppkey) AS supplier_count
    FROM supplier
    GROUP BY s_nationkey
),
ShipValues AS (
    SELECT l_shipmode, SUM(l_extendedprice * (1 - l_discount)) AS total_ship_value
    FROM lineitem
    WHERE l_returnflag = 'N'
    GROUP BY l_shipmode
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, 
           COALESCE(cs.total_acct_balance, 0) AS customer_balance,
           COALESCE(os.total_order_value, 0) AS order_value,
           COALESCE(sd.avg_account_balance, 0) AS supplier_avg_balance,
           COALESCE(sd.supplier_count, 0) AS supplier_count,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY COALESCE(cs.total_acct_balance, 0) DESC) AS row_num
    FROM nation n
    LEFT JOIN CustomerSummary cs ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN OrderSummary os ON n.n_nationkey = cs.c_nationkey
    LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
)
SELECT n.n_name, 
       COALESCE(ps.part_count, 0) AS available_parts,
       (SELECT COUNT(*) FROM lineitem l WHERE l_shipdate BETWEEN '2020-01-01' AND '2020-12-31'
        AND l_returnflag = 'N' AND l_discount > 0) AS total_discounted_items,
       SUM(os.total_order_value) AS total_order_value,
       AVG(customer_balance / NULLIF(supplier_avg_balance, 0)) AS balance_ratio
FROM NationStats n
LEFT JOIN PartSizes ps ON ps.p_size = (SELECT MAX(p_size) FROM part WHERE p_size <= 25)
LEFT JOIN OrderSummary os ON n.n_nationkey = os.o_custkey
WHERE n.n_nationkey IS NOT NULL
GROUP BY n.n_name, ps.part_count
HAVING SUM(os.total_order_value) > 1000 OR COUNT(*) > 10
ORDER BY balance_ratio DESC, total_order_value DESC
LIMIT 50;
