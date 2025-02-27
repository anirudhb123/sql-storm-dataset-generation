WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
LineItemStats AS (
    SELECT 
        l.l_suppkey,
        AVG(l.l_discount) AS avg_discount,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_suppkey
)
SELECT 
    co.c_name,
    co.order_count,
    co.total_spent,
    sp.s_name, 
    sp.total_supply_cost,
    sp.part_count,
    lis.avg_discount,
    lis.total_revenue,
    lis.return_count
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    SupplierParts sp ON co.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%' || sp.s_name || '%')
LEFT JOIN 
    LineItemStats lis ON sp.s_suppkey = lis.l_suppkey
WHERE 
    co.total_spent IS NOT NULL OR sp.total_supply_cost IS NOT NULL
ORDER BY 
    co.total_spent DESC NULLS LAST, 
    sp.total_supply_cost DESC NULLS LAST;
