WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), CustomerOrders AS (
    SELECT 
        c.c_name,
        COALESCE(SUM(RO.total_revenue), 0) AS total_spent,
        COUNT(RO.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders RO ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = RO.o_orderkey)
    GROUP BY 
        c.c_name
), SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
)
SELECT 
    COALESCE(co.c_name, 'Unassigned') AS customer_name,
    co.total_spent,
    co.order_count,
    sp.s_name AS supplier_name,
    sp.p_name AS part_name,
    sp.total_available,
    sp.avg_supply_cost
FROM 
    CustomerOrders co
FULL OUTER JOIN 
    SupplierParts sp ON co.order_count > 10 AND (sp.total_available IS NULL OR sp.total_available > 0)
WHERE 
    co.total_spent > 1000
ORDER BY 
    co.total_spent DESC, sp.avg_supply_cost ASC
LIMIT 100;
