WITH RankedSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           p.p_retailprice, SUM(ps.ps_availqty) AS total_avail_qty
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_retailprice
)
SELECT pd.p_name, pd.p_brand, pd.p_retailprice, pd.total_avail_qty,
       COALESCE(c.total_spent, 0) AS customer_spending,
       CASE 
           WHEN pd.total_avail_qty > 100 THEN 'High Availability'
           WHEN pd.total_avail_qty BETWEEN 50 AND 100 THEN 'Medium Availability'
           ELSE 'Low Availability'
       END AS availability_status,
       COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM PartDetails pd
LEFT JOIN RankedSupplier rs ON pd.p_partkey = rs.ps_partkey AND rs.rnk = 1
LEFT JOIN CustomerOrders c ON c.order_count > 5 AND c.total_spent > 1000
WHERE pd.p_retailprice BETWEEN 10.00 AND 50.00
GROUP BY pd.p_name, pd.p_brand, pd.p_retailprice, pd.total_avail_qty, c.total_spent
ORDER BY pd.p_retailprice DESC, customer_spending DESC;
