WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
OrderStats AS (
    SELECT o.o_custkey, COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM orders o
    GROUP BY o.o_custkey
),
LineItemStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value,
           AVG(l.l_quantity) AS avg_quantity,
           SUM(l.l_tax) AS total_tax
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, 
       COUNT(DISTINCT n.n_nationkey) AS nation_count,
       SUM(CASE WHEN sd.rank <= 5 THEN sd.s_acctbal ELSE 0 END) AS top_supplier_acct_balance,
       AVG(os.total_spent) AS avg_customer_spending,
       SUM(COALESCE(lis.total_line_value, 0)) AS total_order_value,
       COUNT(DISTINCT os.o_custkey) AS distinct_customers
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierDetails sd ON sd.s_nationkey = n.n_nationkey
LEFT JOIN OrderStats os ON os.o_custkey = n.n_nationkey
LEFT JOIN LineItemStats lis ON lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = os.o_custkey)
WHERE r.r_name LIKE '%East%' OR r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_order_value DESC, nation_count DESC;
