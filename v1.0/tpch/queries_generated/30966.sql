WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
),
AggregatedSales AS (
    SELECT 
        COUNT(*) AS order_count,
        SUM(total_sales) AS grand_total_sales
    FROM 
        SalesCTE
),
SupplierRegion AS (
    SELECT 
        s.s_nationkey,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_nationkey, r.r_name
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size >= 10 AND p.p_retailprice > 50.00
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    r.region_name,
    s.supplier_count,
    a.order_count,
    a.grand_total_sales,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    COALESCE(AVG(ps.avg_supply_cost), 0) AS average_supply_cost
FROM 
    SupplierRegion r
JOIN 
    AggregatedSales a 
    ON 1=1
LEFT JOIN 
    PartStats p ON r.s_nationkey = (SELECT n.n_nationkey 
                                     FROM nation n 
                                     WHERE n.n_nationkey = r.s_nationkey)
LEFT JOIN 
    (SELECT s.s_nationkey, ps.avg_supply_cost 
     FROM supplier s 
     JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey 
     GROUP BY s.s_nationkey, ps.ps_supplycost) avg_cost 
    ON r.s_nationkey = avg_cost.s_nationkey
GROUP BY 
    r.region_name, s.supplier_count, a.order_count, a.grand_total_sales;
