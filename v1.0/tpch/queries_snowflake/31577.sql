WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS order_level
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01'
    
    UNION ALL
    
    SELECT 
        oh.o_orderkey,
        oh.o_orderdate,
        oh.o_totalprice,
        oh.order_level + 1
    FROM OrderHierarchy oh
    JOIN orders o ON o.o_orderkey = oh.o_orderkey
    WHERE oh.order_level < 5
),
AggregateSupplier AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost_supply
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(a.total_cost_supply, 0) AS total_supply_cost
    FROM supplier s
    LEFT JOIN AggregateSupplier a ON s.s_suppkey = a.ps_suppkey
),
SalesByRegion AS (
    SELECT 
        n.n_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY n.n_regionkey
),
TopRegions AS (
    SELECT 
        r.r_name,
        sr.total_sales,
        ROW_NUMBER() OVER (ORDER BY sr.total_sales DESC) AS sales_rank
    FROM region r
    JOIN SalesByRegion sr ON r.r_regionkey = sr.n_regionkey
    WHERE sr.total_sales IS NOT NULL
)
SELECT 
    th.r_name AS region_name,
    th.total_sales,
    sd.s_name AS supplier_name,
    sd.total_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY th.r_name ORDER BY th.total_sales DESC) AS region_rank,
    NULLIF(th.total_sales + sd.total_supply_cost, 0) AS combined_sales_cost,
    (SELECT COUNT(*) FROM orders WHERE o_orderstatus = 'F') AS completed_orders
FROM TopRegions th
JOIN SupplierDetails sd ON sd.total_supply_cost > 0
WHERE th.sales_rank <= 5
ORDER BY th.r_name, combined_sales_cost DESC;