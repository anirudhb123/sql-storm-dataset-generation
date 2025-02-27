WITH SupplierInfo AS (
    SELECT s.s_name AS supplier_name, 
           n.n_name AS nation_name, 
           r.r_name AS region_name,
           s.s_acctbal AS account_balance,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PopularProducts AS (
    SELECT p.p_name AS product_name, 
           COUNT(ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_name
    HAVING COUNT(ps.ps_suppkey) > 5
),
CustomerOrders AS (
    SELECT c.c_name AS customer_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT si.supplier_name, 
       si.nation_name, 
       si.region_name, 
       si.account_balance, 
       si.comment_length,
       pp.product_name,
       co.customer_name,
       co.order_count,
       co.total_spent
FROM SupplierInfo si
JOIN PopularProducts pp ON si.comment_length > 50
JOIN CustomerOrders co ON co.order_count > 10
ORDER BY co.total_spent DESC, si.account_balance DESC;
