WITH RankedSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty IS NOT NULL
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerMetrics AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(f.total_sales), 0) AS total_sales,
        COUNT(f.o_orderkey) AS order_count,
        DATEDIFF(DAY, MIN(f.first_order_date), MAX(f.last_order_date)) AS active_days
    FROM 
        customer c
    LEFT JOIN 
        FilteredOrders f ON c.c_custkey = f.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
NationSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(cm.total_sales) AS nation_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        RankedSuppliers rs ON rs.ps_suppkey = s.s_suppkey
    JOIN 
        partsupp ps ON ps.ps_partkey = rs.ps_partkey
    JOIN 
        lineitem l ON l.l_partkey = ps.ps_partkey
    LEFT JOIN 
        FilteredOrders f ON l.l_orderkey = f.o_orderkey
    LEFT JOIN 
        CustomerMetrics cm ON cm.c_custkey = f.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    n.n_name,
    n.nation_sales,
    CASE 
        WHEN n.nation_sales IS NULL THEN 'No Sales'
        WHEN n.nation_sales > (SELECT AVG(nation_sales) FROM NationSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance,
    COALESCE((
        SELECT MAX(total_sales)
        FROM CustomerMetrics
        WHERE order_count > 0
    ), 0) AS max_customer_sales
FROM 
    NationSales n
FULL OUTER JOIN 
    CustomerMetrics cm ON n.n_nationkey = cm.c_custkey
WHERE 
    (n.nation_sales IS NULL OR n.nation_sales < 10000)
    AND cm.order_count IS NOT NULL
ORDER BY 
    n.nation_sales DESC NULLS LAST;
