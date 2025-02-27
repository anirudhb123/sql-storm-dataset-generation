WITH SupplierParts AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, p.p_retailprice
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), CustomerOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_custkey, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), LineItemDetails AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount
    FROM lineitem l
), Summary AS (
    SELECT 
        cp.c_name,
        COUNT(DISTINCT co.o_orderkey) AS total_orders,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
        AVG(ps.p_retailprice) AS avg_part_price,
        COUNT(DISTINCT sp.p_partkey) AS distinct_parts_supplied
    FROM CustomerOrders co
    JOIN CustomerParts cp ON co.o_custkey = cp.c_custkey
    JOIN LineItemDetails lp ON co.o_orderkey = lp.l_orderkey
    JOIN SupplierParts sp ON lp.l_partkey = sp.p_partkey
    GROUP BY cp.c_name
)
SELECT s.*, RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
FROM Summary s
WHERE s.total_orders > 5
ORDER BY revenue_rank, s.avg_part_price DESC
LIMIT 10;
