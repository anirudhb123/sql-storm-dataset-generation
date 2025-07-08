
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1997-12-31'
),
CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MAX(l.l_shipdate) AS last_order_date
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        c.c_acctbal > 1000.00
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_cost,
        SUM(ps.ps_availqty) AS total_availqty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TotalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    cp.c_name,
    r.r_name,
    cp.total_spent,
    cp.order_count,
    cp.last_order_date,
    ss.avg_cost,
    ts.total_sales
FROM 
    CustomerPurchases cp
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = cp.c_custkey)
JOIN 
    SupplierStats ss ON ss.avg_cost IS NOT NULL
LEFT JOIN 
    TotalSales ts ON ts.total_sales = (SELECT MAX(total_sales) FROM TotalSales)
WHERE 
    cp.order_count > 5
    AND cp.last_order_date >= (SELECT MIN(o.o_orderdate) FROM orders o WHERE o.o_orderstatus = 'O')
ORDER BY 
    cp.total_spent DESC
LIMIT 10;
