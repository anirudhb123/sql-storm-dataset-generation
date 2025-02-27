WITH SupplierDetails AS (
    SELECT s_name, s_comment, n_name AS nation_name, r_name AS region_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT p_name, p_brand, p_container, p_retailprice, ps_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT sd.s_name, sd.nation_name, sd.region_name,
       pd.p_name, pd.p_brand, pd.p_container, pd.p_retailprice, pd.ps_supplycost,
       co.c_name, co.o_orderkey, co.o_orderdate, co.total_quantity, co.total_revenue
FROM SupplierDetails sd
JOIN PartDetails pd ON sd.s_comment LIKE CONCAT('%', pd.p_name, '%')
JOIN CustomerOrders co ON co.total_quantity > 10
WHERE sd.region_name IN (SELECT r_name FROM region WHERE r_comment LIKE '%special%')
ORDER BY sd.nation_name, co.total_revenue DESC;
