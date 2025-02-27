WITH SupplierPartCosts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
LineItemDeductions AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'R' 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    n.n_name AS nation,
    SUM(l.total_revenue) AS total_revenue_from_returns,
    COALESCE(SUM(spc.total_cost), 0) AS total_supplier_cost,
    COUNT(DISTINCT hvc.c_custkey) AS high_value_customer_count,
    SUM(CASE WHEN spc.part_count > 5 THEN 1 ELSE 0 END) AS suppliers_with_many_parts
FROM 
    LineItemDeductions l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierPartCosts spc ON spc.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_brand LIKE 'Brand%')
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_custkey = c.c_custkey
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue_from_returns DESC, nation ASC;
