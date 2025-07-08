
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.total_sales,
    r.sales_rank,
    s.s_name,
    s.total_available,
    s.avg_supply_cost,
    c.c_name,
    c.order_count,
    c.total_spent
FROM 
    RankedOrders r
JOIN 
    SupplierInfo s ON s.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0 LIMIT 1)
LEFT JOIN 
    FilteredCustomers c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = r.o_orderkey LIMIT 1)
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC, r.o_orderdate;
