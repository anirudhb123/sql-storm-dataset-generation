WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           ps.ps_supplycost, 
           ps.ps_availqty,
           CONCAT(p.p_name, ' - ', p.p_brand, ' ($', FORMAT(ps.ps_supplycost, 2), '): ', ps.ps_availqty, ' available') AS part_info
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           c.c_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_name
),
SupplierRevenue AS (
    SELECT rs.s_suppkey, 
           rp.part_info, 
           co.total_revenue,
           RANK() OVER (ORDER BY co.total_revenue DESC) AS revenue_rank
    FROM RankedSuppliers rs
    JOIN PartDetails rp ON rs.s_suppkey = rp.p_partkey
    JOIN CustomerOrders co ON co.o_orderkey = rp.p_partkey
    WHERE rs.rk <= 5
)
SELECT sr.s_suppkey, 
       sr.part_info, 
       sr.total_revenue
FROM SupplierRevenue sr
WHERE sr.revenue_rank <= 10
ORDER BY sr.total_revenue DESC;
