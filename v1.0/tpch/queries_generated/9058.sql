WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
),
PopularParts AS (
    SELECT l.l_partkey, p.p_name, SUM(l.l_quantity) AS total_quantity_sold,
           RANK() OVER (ORDER BY SUM(l.l_quantity) DESC) AS part_rank
    FROM lineitem l
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN part p ON p.p_partkey = ps.ps_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY l.l_partkey, p.p_name
),
SupplierPerformance AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_suppkey) AS total_parts_supplied,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT rc.c_name AS top_customer,
       pp.p_name AS top_part,
       sp.s_name AS best_supplier,
       rc.total_spent,
       pp.total_quantity_sold,
       sp.total_parts_supplied,
       sp.avg_supply_cost
FROM RankedCustomers rc
JOIN PopularParts pp ON rc.customer_rank = 1
JOIN SupplierPerformance sp ON sp.total_parts_supplied = (
    SELECT MAX(total_parts_supplied) FROM SupplierPerformance
)
ORDER BY rc.total_spent DESC;
