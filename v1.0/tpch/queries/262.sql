WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) as order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1998-01-01'
), 
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name AS supplier_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, s.s_name
),
OrderLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_items
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '1997-01-01' 
      AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY l.l_orderkey
)

SELECT 
    r.o_orderkey, 
    r.o_orderdate, 
    r.o_totalprice,
    COALESCE(SUM(s.total_available), 0) AS total_available_parts,
    COALESCE(SUM(s.avg_supply_cost), 0) AS average_supply_cost,
    o.total_revenue,
    o.total_items,
    CASE 
        WHEN r.o_totalprice > 1000 THEN 'High Value'
        WHEN r.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM RankedOrders r
LEFT JOIN SupplierPartDetails s ON s.ps_partkey IN (
    SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (
        SELECT ps_suppkey FROM supplier WHERE s_nationkey IN 
        (SELECT n_nationkey FROM nation WHERE n_regionkey = 1)
    )
)
LEFT JOIN OrderLineItems o ON r.o_orderkey = o.l_orderkey
WHERE r.order_rank = 1 
GROUP BY r.o_orderkey, r.o_orderdate, r.o_totalprice, o.total_revenue, o.total_items
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;