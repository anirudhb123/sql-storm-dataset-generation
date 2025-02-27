WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierStats AS (
    SELECT 
        DISTINCT s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
)
SELECT 
    c.c_name AS customer_name,
    r.s_name AS supplier_name,
    ss.part_count AS parts_supplied,
    ss.avg_supply_cost AS average_supply_cost,
    od.total_lineitem_value AS order_value
FROM 
    HighValueCustomers c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    OrderDetails od ON o.o_orderkey = od.o_orderkey
LEFT JOIN 
    RankedSuppliers r ON r.rank = 1
LEFT JOIN 
    SupplierStats ss ON r.s_suppkey = ss.s_suppkey
WHERE 
    od.total_lineitem_value IS NOT NULL 
    AND ss.part_count IS NOT NULL 
    AND ss.avg_supply_cost IS NOT NULL
ORDER BY 
    customer_name, supplier_name;
