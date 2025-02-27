WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.part_count,
        ss.total_value
    FROM 
        SupplierStats ss
    WHERE 
        ss.rank <= 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(os.total_revenue) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    COALESCE(cs.total_spent, 0) AS total_spent,
    ts.s_name AS top_supplier_name,
    ts.total_value AS top_supplier_value
FROM 
    CustomerOrders cs
LEFT JOIN 
    TopSuppliers ts ON cs.order_count > 0
ORDER BY 
    cs.total_spent DESC, cs.c_name ASC;
