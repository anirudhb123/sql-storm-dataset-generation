WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
LineItemStats AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount,
        l.l_returnflag,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) as line_item_rank
    FROM lineitem l
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY l.l_partkey, l.l_returnflag, l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    sp.total_available,
    sp.avg_supply_cost,
    ls.total_quantity,
    ls.avg_discount,
    ls.l_returnflag,
    r.r_name AS region_name,
    CASE 
        WHEN ls.total_quantity IS NULL THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM part p
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN LineItemStats ls ON p.p_partkey = ls.l_partkey
LEFT JOIN supplier s ON sp.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 15)
  AND (r.r_name IS NOT NULL OR r.r_comment IS NOT NULL)
ORDER BY p.p_partkey;
