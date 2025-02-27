
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
),
Combined AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        r.r_name AS region,
        SUM(sp.total_supply_cost) AS total_cost,
        SUM(ro.total_sales) AS total_order_sales
    FROM 
        RankedOrders ro
    LEFT JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (
            SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ro.o_orderkey
            LIMIT 1
        ))
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        SupplierPartDetails sp ON ro.o_orderkey = sp.s_suppkey
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, r.r_name
)
SELECT 
    c.o_orderdate AS order_date,
    CASE 
        WHEN c.total_order_sales IS NULL THEN 'No Sales'
        ELSE 'Total Sales: ' || CAST(c.total_order_sales AS VARCHAR) 
    END AS sales_info,
    COALESCE(c.total_cost, 0) AS total_supply_cost,
    CASE 
        WHEN c.total_cost > 10000 THEN 'High Cost'
        ELSE 'Low Cost/Normal'
    END AS cost_category
FROM 
    Combined c
WHERE 
    c.total_order_sales IS NOT NULL
ORDER BY 
    c.o_orderdate DESC
LIMIT 100;
