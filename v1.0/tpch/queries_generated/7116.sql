WITH SupplierCost AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationRegion AS (
    SELECT n.n_nationkey, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p.p_partkey, p.p_brand, p.p_type, p.p_size, p.p_retailprice, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_brand, p.p_type, p.p_size, p.p_retailprice
)

SELECT nr.r_name AS region_name, pd.p_brand, pd.p_type, pd.p_size, 
       SUM(CASE WHEN co.order_count > 10 THEN co.total_spent END) AS high_spender_total,
       SUM(sc.total_cost) AS supplier_cost_summary,
       COUNT(DISTINCT co.c_custkey) AS active_customers
FROM NationRegion nr
JOIN CustomerOrders co ON nr.n_nationkey = co.c_custkey
JOIN PartDetails pd ON nr.n_regionkey = pd.p_partkey
JOIN SupplierCost sc ON pd.p_partkey = sc.s_suppkey
GROUP BY nr.r_name, pd.p_brand, pd.p_type, pd.p_size
HAVING SUM(CASE WHEN co.order_count > 10 THEN co.total_spent END) IS NOT NULL
ORDER BY region_name, pd.p_brand, pd.p_type;
