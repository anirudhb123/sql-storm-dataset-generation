WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           RANK() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk,
           SUM(ps.ps_availqty) AS total_avail_qty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           FIRST_VALUE(o.o_orderdate) OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate) AS first_order_date
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
DistinctNation AS (
    SELECT DISTINCT n.n_name
    FROM nation n
    WHERE n.n_nationkey IS NOT NULL
),
FilteredLineItems AS (
    SELECT l.l_orderkey, 
           l.l_partkey, 
           l.l_quantity, 
           l.l_extendedprice,
           CASE WHEN l.l_discount > 0.1 THEN 'Discounted' ELSE 'Regular' END AS pricing_category
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
CustomerSupplierInfo AS (
    SELECT co.c_custkey, 
           co.c_name, 
           rs.s_suppkey,
           rs.s_name AS supplier_name,
           rs.total_avail_qty,
           co.total_spent,
           COALESCE(rs.rnk, 0) AS supplier_rank,
           CASE 
               WHEN co.total_spent > 1000 THEN 'High Value'
               WHEN co.total_spent IS NULL THEN 'No Purchases'
               ELSE 'Average Value'
           END AS customer_segment
    FROM CustomerOrders co
    LEFT JOIN RankedSuppliers rs ON co.total_spent > 0 AND co.order_count > 0
)
SELECT csi.c_custkey, 
       csi.c_name, 
       csi.supplier_name, 
       csi.total_avail_qty,
       csi.total_spent,
       csi.supplier_rank,
       csi.customer_segment,
       (SELECT COUNT(*) FROM FilteredLineItems fli WHERE fli.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = csi.c_custkey)) AS associated_line_items
FROM CustomerSupplierInfo csi
JOIN DistinctNation dn ON csi.supplier_name IS NOT DISTINCT FROM dn.n_name
WHERE csi.total_spent IS NOT NULL
ORDER BY csi.customer_segment, csi.total_spent DESC;
