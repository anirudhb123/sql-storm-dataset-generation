WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSupplierData AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost   
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
)
SELECT 
    c.c_name,
    co.total_spent,
    co.order_count,
    ps.part_name,
    ps.total_available,
    ps.avg_supply_cost,
    CASE 
        WHEN co.total_spent > 1000 THEN 'High Spender' 
        WHEN co.total_spent BETWEEN 500 AND 1000 THEN 'Medium Spender' 
        ELSE 'Low Spender' 
    END AS spending_category,
    rs.s_name AS top_supplier
FROM 
    CustomerOrders co
JOIN 
    RankedSuppliers rs ON co.c_custkey = rs.s_suppkey
LEFT JOIN 
    (SELECT 
         p.p_partkey,
         p.p_name AS part_name,
         ps.total_available,
         ps.avg_supply_cost
     FROM 
         part p
     JOIN 
         PartSupplierData ps ON p.p_partkey = ps.ps_partkey) ps ON ps.part_name LIKE '%part%'
WHERE 
    co.order_count > 1
ORDER BY 
    co.total_spent DESC,
    rs.rank_within_nation ASC;
