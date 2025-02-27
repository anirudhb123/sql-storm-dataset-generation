WITH FilteredParts AS (
    SELECT p_partkey, 
           CONCAT('Part: ', p_name, ' [', p_mfgr, '] - Type: ', p_type) AS part_description
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
TopSuppliers AS (
    SELECT s_suppkey, 
           s_name,
           COUNT(DISTINCT ps_partkey) AS num_parts
    FROM supplier
    JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    GROUP BY s_suppkey, s_name
    ORDER BY num_parts DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT DISTINCT o.o_orderkey, 
           c.c_name AS customer_name, 
           o.o_orderdate, 
           CONCAT('Order Total: $', CAST(o.o_totalprice AS VARCHAR)) AS order_total
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT fp.part_description, 
       ts.s_name AS supplier_name, 
       co.customer_name, 
       co.order_total
FROM FilteredParts fp
JOIN partsupp ps ON fp.p_partkey = ps.ps_partkey
JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
JOIN CustomerOrders co ON co.o_orderkey IN (SELECT l_orderkey 
                                             FROM lineitem 
                                             WHERE l_partkey = fp.p_partkey)
WHERE ts.num_parts > 3
ORDER BY fp.part_description, ts.s_name;
