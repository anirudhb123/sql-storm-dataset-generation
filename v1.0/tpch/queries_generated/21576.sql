WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           LEAD(s.s_acctbal) OVER (PARTITION BY s.s_nationkey ORDER BY s.s_suppkey) AS next_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 0
),
NationCTE AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name, 
           (SELECT COUNT(DISTINCT c.c_custkey)
            FROM customer c
            WHERE c.c_nationkey = n.n_nationkey) AS total_customers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSuppCTE AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, 
           SUM(ps.ps_availqty) AS total_availqty,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
CustomerOrderCTE AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity,
           CASE 
               WHEN l.l_discount = 0 THEN l.l_extendedprice
               ELSE l.l_extendedprice * (1 - l.l_discount)
           END AS discounted_price
    FROM lineitem l
    WHERE l.l_shipdate IS NOT NULL
)
SELECT n.n_name, n.region_name, 
       s.s_name,
       COUNT(DISTINCT cu.cust_key) AS customer_count,
       SUM(p.ps_supplycost) AS total_supply_cost,
       SUM(CASE WHEN li.discounted_price IS NULL THEN 0 ELSE li.discounted_price END) AS total_discounted_revenue,
       AVG(sp.next_acctbal) AS avg_next_account_balance
FROM NationCTE n
LEFT JOIN SupplierCTE sp ON n.n_nationkey = sp.s_nationkey
LEFT JOIN PartSuppCTE p ON p.ps_partkey IN (SELECT DISTINCT l.l_partkey FROM FilteredLineItems l)
LEFT JOIN CustomerOrderCTE cu ON cu.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN FilteredLineItems li ON li.l_orderkey = ANY(SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cu.c_custkey)
WHERE n.total_customers > 5
GROUP BY n.n_name, n.region_name, s.s_name
HAVING COUNT(DISTINCT cu.cust_key) > 10
ORDER BY total_supply_cost DESC NULLS LAST;
