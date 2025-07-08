
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS parts_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_nationkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank,
        c.c_nationkey
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
NationalSales AS (
    SELECT 
        n.n_nationkey,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey
)
SELECT 
    n.n_name,
    COALESCE(hvc.cust_count, 0) AS high_value_cust_count,
    COALESCE(ss.parts_count, 0) AS supplier_parts_count,
    ns.total_sales
FROM 
    nation n
LEFT JOIN 
    (SELECT 
        c_nationkey, COUNT(c_custkey) AS cust_count 
     FROM 
        HighValueCustomers 
     GROUP BY 
        c_nationkey) hvc ON n.n_nationkey = hvc.c_nationkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
FULL OUTER JOIN 
    NationalSales ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    total_sales DESC, high_value_cust_count DESC;
