WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_supplycost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 5
),
CustomerOrders AS (
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
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        lo.l_partkey,
        lo.l_suppkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate >= DATE '1997-01-01' AND lo.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        lo.l_orderkey, lo.l_partkey, lo.l_suppkey
)
SELECT 
    cn.n_name AS nation_name,
    ts.s_name AS supplier_name,
    co.c_name AS customer_name,
    co.order_count,
    co.total_spent,
    SUM(od.revenue) AS total_revenue
FROM 
    TopSuppliers ts
JOIN 
    nation cn ON ts.s_suppkey = cn.n_nationkey
JOIN 
    CustomerOrders co ON ts.s_suppkey = co.c_custkey
LEFT JOIN 
    OrderDetails od ON co.order_count = (
        SELECT 
            COUNT(*) 
        FROM 
            orders o2 
        WHERE 
            o2.o_orderkey = od.l_orderkey
    )
WHERE 
    (co.total_spent > 10000 OR ts.total_supplycost IS NULL)
GROUP BY 
    cn.n_name, ts.s_name, co.c_name, co.order_count, co.total_spent
HAVING 
    SUM(od.revenue) > (SELECT AVG(revenue) FROM OrderDetails)
ORDER BY 
    total_revenue DESC;