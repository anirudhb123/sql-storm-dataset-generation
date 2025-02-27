WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.ps_supplycost,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
), HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) as rn
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 5000
), RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (ORDER BY o.o_orderdate DESC) as order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
)
SELECT 
    r_region.r_name,
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM 
    region r_region
JOIN 
    nation n ON r_region.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_suppkey = rs.s_suppkey
JOIN 
    RecentOrders ro ON ro.o_orderkey = l.l_orderkey
JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = ro.o_custkey
WHERE 
    rs.rank = 1
GROUP BY 
    r_region.r_name, n.n_name
HAVING 
    AVG(s.s_acctbal) > 10000
ORDER BY 
    total_sales DESC, high_value_customer_count DESC;
