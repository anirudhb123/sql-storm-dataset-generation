
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_linenumber) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey
),
CustomerOrder AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(od.total_order_value) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSupplier AS (
    SELECT 
        n.n_nationkey,
        r.r_regionkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, r.r_regionkey
)
SELECT 
    r.r_name,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    s.total_supply_value,
    CASE 
        WHEN cs.order_count > 0 THEN (s.total_supply_value / cs.total_spent)
        ELSE NULL
    END AS supply_to_spend_ratio,
    rs.supplier_count
FROM 
    CustomerOrder cs
JOIN 
    SupplierStats s ON s.unique_parts >= 10
JOIN 
    region r ON r.r_regionkey IN (SELECT r_regionkey FROM RegionSupplier WHERE supplier_count > 5)
LEFT JOIN 
    RegionSupplier rs ON rs.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
