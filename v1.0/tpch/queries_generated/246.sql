WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
BestSuppliers AS (
    SELECT 
        r.r_name,
        n.n_name,
        rs.s_name,
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank = 1
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    co.o_orderkey,
    co.total_order_value,
    bs.s_name AS best_supplier_name,
    bs.total_supply_cost,
    COALESCE(SUM(c.c_acctbal), 0) AS total_customer_balance,
    CASE 
        WHEN co.line_count > 10 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_volume_category
FROM 
    CustomerOrders co
LEFT JOIN 
    BestSuppliers bs ON co.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Corp%' LIMIT 1)
LEFT JOIN 
    customer c ON co.o_custkey = c.c_custkey
GROUP BY 
    co.o_orderkey, 
    co.total_order_value, 
    bs.s_name, 
    bs.total_supply_cost, 
    order_volume_category
HAVING 
    total_order_value > 1000
ORDER BY 
    total_order_value DESC;
