WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        SUM(ps_supplycost * ps_availqty) AS total_supplycost,
        COUNT(DISTINCT ps_partkey) AS unique_parts
    FROM 
        supplier
    JOIN 
        partsupp ON s_suppkey = ps_suppkey
    GROUP BY 
        s_nationkey
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        SUM(ss.total_supplycost) AS region_supply
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
    HAVING 
        COUNT(distinct ss.unique_parts) > 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS status_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
)
SELECT 
    r.r_name,
    od.o_orderkey,
    od.order_total,
    od.o_orderdate,
    CASE 
        WHEN od.status_rank = 1 THEN 'Highest'
        WHEN od.status_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS order_rank
FROM 
    TopRegions r
JOIN 
    OrderDetails od ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = od.o_orderkey)
WHERE 
    od.order_total IS NOT NULL
ORDER BY 
    r.r_name, order_total DESC;
