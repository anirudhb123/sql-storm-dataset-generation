WITH CustomerInfo AS (
    SELECT c.c_custkey, c.c_name, n.n_name AS nation, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, n.n_name
),
PopularParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(l.l_orderkey) AS order_count
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    ORDER BY order_count DESC
    LIMIT 10
),
DetailedSupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT ci.c_name, ci.nation, ci.total_spent, pp.p_name AS popular_part, dsi.s_name AS supplier_name, dsi.ps_supplycost
FROM CustomerInfo ci
JOIN PopularParts pp ON ci.total_spent > 1000
JOIN DetailedSupplierInfo dsi ON pp.p_partkey = dsi.p_partkey
WHERE ci.total_spent > (
    SELECT AVG(total_spent) FROM CustomerInfo
)
ORDER BY ci.total_spent DESC, pp.order_count DESC;
