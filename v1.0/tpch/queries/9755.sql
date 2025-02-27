WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_lineitem_value
    FROM RankedOrders ro
    JOIN lineitem li ON ro.o_orderkey = li.l_orderkey
    WHERE ro.order_rank <= 10
    GROUP BY ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, ro.o_orderstatus
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    hvo.total_lineitem_value,
    sd.s_name,
    sd.total_supply_cost
FROM HighValueOrders hvo
JOIN SupplierDetails sd ON hvo.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderdate = hvo.o_orderdate)
ORDER BY hvo.o_totalprice DESC, sd.total_supply_cost ASC
LIMIT 50;