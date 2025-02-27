WITH SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_availability, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, COUNT(l.l_linenumber) AS item_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) 
                          FROM customer c2 
                          WHERE c2.c_nationkey = c.c_nationkey)
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation_name, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(o.total_revenue) AS total_revenue,
    MAX(s.total_availability) AS max_supplier_availability,
    MIN(s.avg_supply_cost) AS min_avg_supply_cost
FROM nation n
LEFT JOIN FilteredCustomers c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderStats o ON c.c_custkey = o.o_orderkey
JOIN SupplierStats s ON s.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > (
        SELECT AVG(ps2.ps_availqty) 
        FROM partsupp ps2 
        WHERE ps2.ps_partkey = (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_brand = 'Brand#44'
            LIMIT 1
        )
    )
)
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY nation_name;
