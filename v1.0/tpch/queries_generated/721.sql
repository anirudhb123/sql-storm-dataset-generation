WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(year, -1, GETDATE())
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_available
    FROM 
        SupplierParts sp
    WHERE 
        sp.total_available > 1000
),
OrdersDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_suppkey,
        lo.l_quantity,
        lo.l_extendedprice,
        lo.l_discount,
        lo.l_tax,
        lo.l_shipdate,
        lo.l_returnflag,
        lo.l_linestatus
    FROM 
        lineitem lo
)
SELECT 
    c.c_name,
    COALESCE(cs.total_spent, 0) AS total_spending,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(od.l_extendedprice) AS avg_line_price,
    MAX(ro.o_totalprice) AS max_order_price,
    COUNT(DISTINCT ts.s_name) AS unique_suppliers
FROM 
    customer c
LEFT JOIN 
    CustomerSpending cs ON c.c_custkey = cs.c_custkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrdersDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN 
    RankedOrders ro ON o.o_orderkey = ro.o_orderkey
LEFT JOIN 
    TopSuppliers ts ON od.l_suppkey = ts.s_suppkey
WHERE 
    c.c_acctbal IS NOT NULL
    AND c.c_mktsegment IN ('BUILDING', 'FURNITURE')
GROUP BY 
    c.c_name
HAVING 
    AVG(od.l_extendedprice) > 100
ORDER BY 
    total_spending DESC;
