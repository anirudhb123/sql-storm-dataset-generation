WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), 
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_mktsegment
    FROM RankedOrders r
    WHERE r.rn <= 10
),
OrderLineItems AS (
    SELECT 
        o.o_orderkey,
        l.l_itemkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM TopOrders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        s.s_name AS supplier_name,
        ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.c_mktsegment,
    SUM(li.l_quantity) AS total_quantity,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    COUNT(DISTINCT sp.supplier_name) AS supplier_count,
    AVG(sp.ps_supplycost) AS avg_supply_cost
FROM TopOrders o
JOIN OrderLineItems li ON o.o_orderkey = li.o_orderkey
JOIN SupplierParts sp ON li.l_itemkey = sp.ps_partkey
GROUP BY 
    o.o_orderkey, 
    o.o_orderdate, 
    o.o_totalprice, 
    o.c_mktsegment
ORDER BY 
    o.o_orderdate DESC, 
    total_revenue DESC
LIMIT 100;
