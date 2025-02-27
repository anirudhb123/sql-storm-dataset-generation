WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) > 100
),
HighValueSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3 AND rs.s_acctbal IS NOT NULL
),
FinalResult AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        p.p_partkey,
        p.p_name,
        p.total_supply_cost,
        r.r_name AS supplier_region,
        hs.s_name AS high_value_supplier,
        CASE 
            WHEN co.total_orders IS NULL THEN 'No Orders'
            ELSE CONCAT('Total Orders: ', co.total_orders)
        END AS order_summary,
        CASE 
            WHEN p.total_supply_cost IS NULL THEN 'Not Available'
            ELSE CONCAT('Total Supply Cost: $', ROUND(p.total_supply_cost, 2))
        END AS cost_summary
    FROM 
        CustomerOrders co
    FULL OUTER JOIN 
        PartDetails p ON co.c_custkey = (SELECT MAX(o.o_custkey) FROM orders o WHERE o.o_orderkey) 
    FULL OUTER JOIN 
        HighValueSuppliers hs ON hs.s_acctbal BETWEEN 5000 AND 10000
    WHERE 
        (co.total_orders IS NOT NULL OR p.p_partkey IS NULL) 
        AND (hs.s_name IS NOT NULL OR r.r_name IS NOT NULL)
)
SELECT 
    *,
    ROW_NUMBER() OVER (PARTITION BY supplier_region ORDER BY p_partkey) AS row_num
FROM 
    FinalResult
WHERE 
    (total_supply_cost > 10000 OR supplier_region LIKE 'S%')
ORDER BY 
    supplier_region, p_name DESC;
