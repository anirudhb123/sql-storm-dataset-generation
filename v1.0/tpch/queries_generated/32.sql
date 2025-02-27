WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_clerk,
        ROW_NUMBER() OVER (PARTITION BY o.o_clerk ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 100
),
SalesAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_sales,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    coalesce(cs.c_name, 'Unknown') AS customer_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(cs.total_spent) AS total_spending,
    COUNT(DISTINCT sa.l_orderkey) AS orders_with_lineitems,
    MAX(sa.net_sales) AS max_net_sales,
    MAX(rs.o_orderdate) AS latest_order_date,
    ts.s_name AS top_supplier
FROM 
    CustomerSummary cs
LEFT JOIN 
    orders o ON cs.c_custkey = o.o_custkey
LEFT JOIN 
    SalesAnalysis sa ON o.o_orderkey = sa.l_orderkey
LEFT JOIN 
    RankedOrders rs ON o.o_orderkey = rs.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON sa.supplier_count = 1
WHERE 
    cs.total_spent IS NOT NULL
GROUP BY 
    coalesce(cs.c_name, 'Unknown'), ts.s_name
ORDER BY 
    total_spending DESC
LIMIT 
    50;
