WITH SupplierDetails AS (
    SELECT s.s_name, n.n_name, r.r_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, n.n_name, r.r_name
),
CustomerOrders AS (
    SELECT c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_totalprice > 1000
),
LineItemDetails AS (
    SELECT o.o_orderkey, COUNT(DISTINCT l.l_linenumber) AS item_count, SUM(l.l_extendedprice) AS total_extended_price
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY o.o_orderkey
)
SELECT sd.s_name, sd.n_name, sd.r_name, COUNT(DISTINCT co.o_orderkey) AS order_count,
       SUM(co.o_totalprice) AS total_order_value, ld.item_count, ld.total_extended_price,
       CONCAT('Supplier: ', sd.s_name, ', Nation: ', sd.n_name, ', Region: ', sd.r_name) AS supplier_info,
       CONCAT('Orders Count: ', COUNT(DISTINCT co.o_orderkey), ', Total Order Value: ', SUM(co.o_totalprice)) AS order_summary
FROM SupplierDetails sd
LEFT JOIN CustomerOrders co ON sd.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_name = sd.s_name))
LEFT JOIN LineItemDetails ld ON co.o_orderkey = ld.o_orderkey
GROUP BY sd.s_name, sd.n_name, sd.r_name, ld.item_count, ld.total_extended_price
ORDER BY total_supply_cost DESC, order_count DESC;
