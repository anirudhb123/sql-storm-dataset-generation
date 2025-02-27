WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS line_count,
        o.o_orderdate,
        o.o_orderstatus
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_orderstatus
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        o.o_orderkey,
        o.total_price,
        o.o_orderdate
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary o ON c.c_custkey = o.o_orderkey
),
FinalSummary AS (
    SELECT 
        r.r_name,
        COALESCE(SUM(oi.total_price), 0) AS total_revenue,
        COUNT(DISTINCT oi.o_orderkey) AS order_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        CustomerOrderInfo oi ON ps.ps_partkey = oi.o_orderkey
    GROUP BY 
        r.r_name
)
SELECT 
    fs.r_name,
    fs.total_revenue,
    fs.order_count,
    fs.customer_count,
    rs.total_supply_cost
FROM 
    FinalSummary fs
JOIN 
    RankedSuppliers rs ON rs.rank <= 10
WHERE 
    fs.total_revenue IS NOT NULL
ORDER BY 
    fs.total_revenue DESC
LIMIT 5;
