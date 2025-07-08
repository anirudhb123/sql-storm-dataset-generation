
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_mktsegment, 
        DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_mktsegment
    FROM RankedOrders r
    WHERE r.price_rank <= 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
),
OrderLineDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(l.l_partkey) AS item_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_mktsegment,
    COALESCE(l.revenue, 0) AS total_revenue,
    COALESCE(s.total_supply_value, 0) AS supplier_value,
    CASE 
        WHEN o.o_totalprice IS NULL THEN 'No Price' 
        WHEN o.o_totalprice > 1000 THEN 'High Value'
        ELSE 'Regular Value' 
    END AS order_value_category
FROM TopOrders o
LEFT JOIN OrderLineDetails l ON o.o_orderkey = l.l_orderkey
LEFT JOIN (
    SELECT ps.ps_suppkey, li.l_orderkey
    FROM partsupp ps 
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey 
) AS subquery ON subquery.l_orderkey = o.o_orderkey
LEFT JOIN SupplierStats s ON s.s_suppkey = subquery.ps_suppkey
ORDER BY o.o_orderdate DESC;
