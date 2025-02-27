WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           CONCAT(s.s_name, ' from nation ', n.n_name) AS supplier_details
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           CONCAT(p.p_name, ' is supplied by ', s.s_name) AS part_supplier_details
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN SupplierInfo s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrderInfo AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate,
           CONCAT(c.c_name, ' placed order ', o.o_orderkey, ' on ', o.o_orderdate) AS customer_order_details
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
LineItemDetails AS (
    SELECT li.l_orderkey, li.l_linenumber, li.l_partkey, li.l_quantity,
           CONCAT('Order ', li.l_orderkey, ' includes ', li.l_quantity, ' units of part ', p.p_name) AS line_item_details
    FROM lineitem li
    JOIN part p ON li.l_partkey = p.p_partkey
)
SELECT 
    s.supplier_details,
    ps.part_supplier_details,
    co.customer_order_details,
    li.line_item_details
FROM SupplierInfo s
JOIN PartSupplierInfo ps ON s.s_suppkey = ps.ps_suppkey
JOIN CustomerOrderInfo co ON EXISTS (
    SELECT 1 FROM lineitem li WHERE li.l_partkey = ps.ps_partkey AND li.l_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = co.c_custkey
    )
)
JOIN LineItemDetails li ON li.l_orderkey = co.o_orderkey AND li.l_partkey = ps.ps_partkey
ORDER BY s.supplier_details, co.customer_order_details;
