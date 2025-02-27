WITH RECURSIVE SalesData AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        customer AS c
    JOIN 
        orders AS o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' -- Filter for the current year
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(total_sales) AS total_sales
    FROM 
        SalesData
    JOIN 
        customer AS c ON SalesData.c_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(total_sales) > 10000 -- Only including customers with significant sales
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        (SUM(ps.ps_availqty) - COALESCE(NULLIF(SUM(l.l_quantity), 0), 0)) AS available_after_sales
    FROM 
        supplier AS s
    JOIN 
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part AS p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem AS l ON ps.ps_partkey = l.l_partkey AND l.l_shipdate >= CURRENT_DATE - INTERVAL '30 days' 
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_name
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_sales,
    si.s_name,
    si.p_name,
    si.available_after_sales
FROM 
    TopCustomers AS tc
JOIN 
    SupplierInfo AS si ON si.available_after_sales > 0
ORDER BY 
    tc.total_sales DESC, si.available_after_sales DESC
LIMIT 10;
