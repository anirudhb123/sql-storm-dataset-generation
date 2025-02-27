WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        1 AS order_level
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= DATE '1996-01-01'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey + 1
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE oh.order_level < 5
),
SupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
PartSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity_sold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
    GROUP BY p.p_partkey
)
SELECT 
    nh.c_name,
    COALESCE(ps.total_quantity_sold, 0) AS quantity_sold,
    COALESCE(ss.total_available, 0) AS supplier_availability,
    ps.total_sales,
    nh.o_totalprice,
    ROW_NUMBER() OVER (PARTITION BY nh.o_orderkey ORDER BY ps.total_sales DESC) AS sales_rank
FROM OrderHierarchy nh
LEFT JOIN PartSales ps ON nh.o_orderkey = ps.p_partkey
LEFT JOIN SupplierStats ss ON ps.p_partkey = ss.ps_partkey
WHERE nh.o_orderstatus = 'O' AND nh.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY nh.o_orderdate DESC, sales_rank
LIMIT 100;