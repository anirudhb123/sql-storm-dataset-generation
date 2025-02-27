WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplier,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        s.s_nationkey,
        ss.s_suppkey,
        ss.s_name,
        ss.total_supply_cost,
        ss.distinct_parts_supplier
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.rn <= 5
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        c.c_name,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, c.c_name, o.o_totalprice, o.o_orderdate
),
FinalResult AS (
    SELECT 
        COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
        o.total_revenue,
        ts.s_name AS top_supplier_name,
        ts.total_supply_cost
    FROM 
        CustomerOrders o
    LEFT JOIN 
        TopSuppliers ts ON o.o_custkey IN (SELECT c_custkey FROM customer WHERE c_nationkey = ts.s_nationkey)
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
)
SELECT 
    fr.customer_name,
    fr.total_revenue,
    fr.top_supplier_name,
    fr.total_supply_cost
FROM 
    FinalResult fr
WHERE 
    fr.total_revenue IS NOT NULL
    AND (fr.total_supply_cost > 5000 OR fr.total_supply_cost IS NULL)
ORDER BY 
    fr.total_revenue DESC;
