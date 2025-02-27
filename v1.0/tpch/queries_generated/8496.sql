WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderkey < o.o_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
),
SupplierProducts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
RevenueByRegion AS (
    SELECT n.n_name AS region_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, 
       sr.region_name, sp.s_name, sp.p_name, 
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned_value,
       r.total_revenue
FROM CustomerOrders co
LEFT JOIN lineitem l ON co.o_orderkey = l.l_orderkey
JOIN SupplierProducts sp ON l.l_suppkey = sp.s_suppkey
JOIN nation n ON sp.s_suppkey = n.n_nationkey
JOIN RevenueByRegion r ON n.n_name = r.region_name
WHERE co.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, sr.region_name, sp.s_name, sp.p_name, r.total_revenue
ORDER BY total_returned_value DESC, co.o_orderdate;
