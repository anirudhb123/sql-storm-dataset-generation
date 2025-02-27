WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        ns.n_name,
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation ns ON rs.s_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(oi.l_extendedprice * (1 - oi.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem oi ON o.o_orderkey = oi.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
SupplierOrders AS (
    SELECT 
        ts.s_suppkey,
        ts.s_name,
        COUNT(DISTINCT o.o_orderkey) AS num_orders,
        SUM(oi.l_extendedprice) AS total_order_value
    FROM 
        TopSuppliers ts
    JOIN 
        partsupp ps ON ts.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem oi ON ps.ps_partkey = oi.l_partkey
    JOIN 
        orders o ON oi.l_orderkey = o.o_orderkey
    GROUP BY 
        ts.s_suppkey, ts.s_name
)
SELECT 
    co.c_custkey,
    co.c_name,
    so.s_suppkey,
    so.s_name,
    so.num_orders,
    so.total_order_value,
    co.total_spent,
    CASE 
        WHEN so.total_order_value > co.total_spent THEN 'Supplier'
        ELSE 'Customer'
    END AS relation_type
FROM 
    CustomerOrders co
JOIN 
    SupplierOrders so ON co.total_spent >= (SELECT AVG(total_spent) FROM CustomerOrders)
ORDER BY 
    co.total_spent DESC, so.total_order_value DESC;
