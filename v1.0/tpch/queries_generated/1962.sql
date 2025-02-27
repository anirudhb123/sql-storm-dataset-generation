WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierAvailability AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_discount,
        lo.l_quantity,
        lo.l_extendedprice,
        lo.l_returnflag,
        lo.l_linestatus,
        CAST(n.n_name AS VARCHAR(25)) AS nation_name
    FROM 
        lineitem lo
    JOIN 
        orders o ON lo.l_orderkey = o.o_orderkey
    JOIN 
        supplier s ON lo.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        lo.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2023-01-01'
)
SELECT 
    RANK() OVER (ORDER BY SUM(od.l_extendedprice * (1 - od.l_discount)) DESC) AS sales_rank,
    od.nation_name,
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(MAX(hvc.total_spent), 0) AS customer_spending
FROM 
    OrderDetails od
LEFT JOIN 
    RankedOrders o ON od.l_orderkey = o.o_orderkey
LEFT JOIN 
    HighValueCustomers hvc ON od.l_orderkey IN (
        SELECT 
            o.o_orderkey 
        FROM 
            orders o 
        JOIN 
            customer c ON o.o_custkey = c.c_custkey 
        WHERE 
            c.c_custkey = hvc.c_custkey
    )
GROUP BY 
    od.nation_name
HAVING 
    total_sales > 10000
ORDER BY 
    total_sales DESC;
