WITH NationSupplier AS (
    SELECT n.n_name AS nation_name, s.s_name AS supplier_name, s.s_acctbal AS account_balance
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
),
PartSupplier AS (
    SELECT p.p_name AS part_name, ps.ps_supplycost AS supply_cost, ps.ps_availqty AS available_quantity
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_name AS customer_name, o.o_orderkey AS order_key, o.o_totalprice AS order_total
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
DetailedData AS (
    SELECT ns.nation_name, ns.supplier_name, ps.part_name, ps.supply_cost, ps.available_quantity, co.customer_name, co.order_key, co.order_total
    FROM NationSupplier ns
    JOIN PartSupplier ps ON ns.nation_name LIKE CONCAT('%', SUBSTRING(ps.part_name, 1, 5), '%')
    CROSS JOIN CustomerOrders co
)
SELECT 
    nation_name,
    supplier_name,
    COUNT(DISTINCT part_name) AS distinct_parts_supplied,
    SUM(supply_cost * available_quantity) AS total_supply_value,
    AVG(order_total) AS average_order_value
FROM DetailedData
GROUP BY nation_name, supplier_name
HAVING SUM(supply_cost * available_quantity) > 10000
ORDER BY total_supply_value DESC, average_order_value ASC;
