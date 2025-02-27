WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, p.p_size, ps.ps_availqty, 
           CONCAT(s.s_name, ' supplies ', p.p_name, ' in quantity ', CAST(ps.ps_availqty AS VARCHAR), 
                  ' of size ', CAST(p.p_size AS VARCHAR)) AS supply_comment
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, 
           CONCAT(c.c_name, ' has order ', CAST(o.o_orderkey AS VARCHAR), 
                  ' with status ', o.o_orderstatus) AS order_comment
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
AggregatedComments AS (
    SELECT sp.supply_comment, co.order_comment,
           CONCAT(sp.supply_comment, ' // ', co.order_comment) AS combined_comment
    FROM SupplierParts sp
    JOIN CustomerOrders co ON sp.s_suppkey % 10 = co.c_custkey % 10
)
SELECT DISTINCT combined_comment
FROM AggregatedComments
WHERE combined_comment LIKE '%supplies%'
AND combined_comment LIKE '%order%';
