WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY YEAR(o.o_orderdate) ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM RankedOrders r
    WHERE r.OrderRank <= 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighValueItems AS (
    SELECT 
        lp.l_orderkey,
        lp.l_partkey,
        lp.l_extendedprice,
        lp.l_discount,
        pp.p_name,
        pp.supplier_name
    FROM lineitem lp
    JOIN TopOrders to ON lp.l_orderkey = to.o_orderkey
    JOIN SupplierParts pp ON lp.l_partkey = pp.ps_partkey
    WHERE (lp.l_extendedprice - lp.l_discount * lp.l_extendedprice) > 10000
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.c_name,
    COUNT(*) AS total_items,
    SUM(hv.l_extendedprice - hv.l_discount * hv.l_extendedprice) AS total_revenue,
    STRING_AGG(DISTINCT hv.p_name, ', ') AS items_names,
    STRING_AGG(DISTINCT hv.supplier_name, ', ') AS suppliers_names
FROM TopOrders to
LEFT JOIN HighValueItems hv ON to.o_orderkey = hv.l_orderkey
GROUP BY to.o_orderkey, to.o_orderdate, to.c_name
ORDER BY total_revenue DESC
LIMIT 10;
