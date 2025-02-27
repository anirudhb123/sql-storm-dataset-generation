WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        RANK() OVER (PARTITION BY s.n_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.n_nationkey
),
OrderLineStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_count,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name,
    COALESCE(SU.total_available, 0) AS total_available,
    COALESCE(OS.total_sales, 0) AS total_sales,
    CASE 
        WHEN SU.total_available IS NULL THEN 'No Suppliers'
        ELSE 'Suppliers Present'
    END AS supplier_status,
    CASE 
        WHEN OS.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status
FROM 
    nation n
LEFT JOIN 
    SupplierStats SU ON n.n_nationkey = SU.n_nationkey AND SU.rank_within_nation <= 5
FULL OUTER JOIN 
    OrderLineStats OS ON SU.s_suppkey = OS.l_orderkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%East%')
ORDER BY 
    n.n_name, total_sales DESC;
