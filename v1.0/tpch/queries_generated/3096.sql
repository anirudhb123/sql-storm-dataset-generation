WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT 
        li.l_orderkey, 
        li.l_partkey, 
        li.l_quantity, 
        p.p_name, 
        p.p_retailprice, 
        (li.l_extendedprice * (1 - li.l_discount)) AS effective_price
    FROM 
        lineitem li
    JOIN 
        part p ON li.l_partkey = p.p_partkey
    WHERE 
        li.l_shipdate >= DATE '2023-01-01'
),
SupplierPartCosts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)

SELECT 
    c.c_name AS customer_name,
    COALESCE(so.total_spent, 0) AS total_spent,
    SUM(od.effective_price) AS total_order_value,
    COALESCE(rs.s_name, 'No Supplier') AS top_supplier,
    COALESCE(SUM(spc.total_cost), 0) AS supplier_costs
FROM 
    CustomerOrders so
LEFT JOIN 
    OrderDetails od ON so.c_custkey = od.l_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rnk = 1 AND od.l_partkey IN (SELECT ps_partkey FROM partsupp)
LEFT JOIN 
    SupplierPartCosts spc ON od.l_partkey = spc.ps_partkey
GROUP BY 
    so.c_custkey, so.c_name, rs.s_name
HAVING 
    SUM(od.effective_price) > 1000
ORDER BY 
    total_spent DESC, total_order_value DESC
LIMIT 100;
