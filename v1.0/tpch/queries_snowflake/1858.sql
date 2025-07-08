
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        region r
    LEFT JOIN 
        RankedSuppliers rs ON r.r_regionkey = rs.rank
    WHERE 
        rs.rank <= 3
),
OrderTotals AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(ot.total_amount) AS avg_order_amount
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderTotals ot ON o.o_orderkey = ot.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.avg_order_amount,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier
FROM 
    CustomerStats cs
LEFT JOIN 
    TopSuppliers ts ON cs.order_count = (SELECT COUNT(*) FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE 
    cs.avg_order_amount > (SELECT AVG(avg_order_amount) FROM CustomerStats) 
AND 
    cs.order_count > 0
ORDER BY 
    cs.avg_order_amount DESC;
