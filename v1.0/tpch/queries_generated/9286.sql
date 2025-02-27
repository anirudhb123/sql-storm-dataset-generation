WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_mktsegment, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
HighValueOrders AS (
    SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, r.c_mktsegment
    FROM RankedOrders r
    WHERE r.rnk <= 10
),
SupplierDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_supplycost, p.p_brand, p.p_type
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
OrderLineItem AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN HighValueOrders h ON l.l_orderkey = h.o_orderkey
    GROUP BY l.l_orderkey
)
SELECT h.o_orderkey, h.o_orderdate, h.o_totalprice, h.c_mktsegment, 
       SUM(sd.ps_supplycost) AS total_supply_cost, 
       ol.total_sales
FROM HighValueOrders h
LEFT JOIN OrderLineItem ol ON h.o_orderkey = ol.l_orderkey
JOIN SupplierDetails sd ON EXISTS (
    SELECT 1 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT l.l_partkey 
        FROM lineitem l 
        WHERE l.l_orderkey = h.o_orderkey
    ) AND ps.ps_suppkey = sd.ps_suppkey
)
GROUP BY h.o_orderkey, h.o_orderdate, h.o_totalprice, h.c_mktsegment, ol.total_sales
ORDER BY h.o_totalprice DESC;
