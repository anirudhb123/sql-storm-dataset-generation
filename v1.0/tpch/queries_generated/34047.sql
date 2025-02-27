WITH RECURSIVE RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), 
PartSales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY p.p_partkey
)
SELECT 
    np.n_name AS nation_name,
    ps.p_name AS part_name,
    cs.total_spent,
    COALESCE(ps.total_sales, 0) AS total_sales,
    CASE WHEN cs.total_spent > 10000 THEN 'High Value' ELSE 'Low Value' END AS customer_value,
    CASE WHEN rs.s_suppkey IS NULL THEN 'Not Available' ELSE rs.s_name END AS supplier_name
FROM nation np
LEFT JOIN CustomerOrders cs ON np.n_nationkey = cs.c_nationkey
LEFT JOIN PartSales ps ON cs.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = np.n_nationkey LIMIT 1)
LEFT JOIN RankedSuppliers rs ON np.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = rs.s_suppkey)
WHERE np.r_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
ORDER BY np.n_name, cs.total_spent DESC;
