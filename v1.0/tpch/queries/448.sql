WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
NationSummary AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate <= DATE '1995-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    ns.n_name,
    ns.customer_count,
    ns.avg_supplier_balance,
    COALESCE(hvo.total_order_value, 0) AS total_order_value
FROM 
    NationSummary ns
LEFT JOIN 
    HighValueOrders hvo ON ns.n_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = hvo.o_orderkey % 5) 
WHERE 
    ns.customer_count > 0
ORDER BY 
    ns.customer_count DESC, 
    ns.avg_supplier_balance DESC;