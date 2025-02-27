WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
), 
CustomerAggregates AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), 
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, p.p_partkey
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    ca.c_custkey,
    COALESCE(MAX(ra.o_totalprice), 0) AS max_order_price,
    COALESCE(MAX(spd.total_available), 0) AS total_available_parts,
    COALESCE(SUM(spd.avg_cost), 0) AS avg_supplier_cost,
    CASE 
        WHEN EXISTS (SELECT 1 FROM lineitem l WHERE l.l_discount > 0) 
        THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS discount_status
FROM CustomerAggregates ca
LEFT JOIN RankedOrders ra ON ca.c_custkey = ra.o_orderkey
LEFT JOIN SupplierPartDetails spd ON spd.total_available > 0
GROUP BY ca.c_custkey
HAVING (count(ca.order_count) > 5 OR max_order_price > 1000.00) 
   AND EXISTS (SELECT 1 FROM TopSuppliers ts WHERE ts.supplier_rank <= 5 AND ts.s_suppkey = spd.s_suppkey)
ORDER BY ca.c_custkey DESC
LIMIT 10;
