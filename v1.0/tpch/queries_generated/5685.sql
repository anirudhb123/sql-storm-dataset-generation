WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
), TopSegmentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment
    FROM RankedOrders o
    JOIN customer c ON o.o_orderkey = c.c_custkey
    WHERE o.rn <= 5
), LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.total_sales,
    t.total_quantity,
    c.c_name,
    c.c_address,
    n.n_name AS nation_name,
    r.r_name AS region_name
FROM TopSegmentOrders t
JOIN LineItemDetails l ON t.o_orderkey = l.l_orderkey
JOIN customer c ON t.o_orderkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
ORDER BY total_sales DESC, total_quantity DESC;
