WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER(PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(ro.o_orderkey) AS order_count,
        SUM(ro.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        RankedOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
HighSpenderSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        supplier s
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    JOIN 
        customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(total_spent) FROM CustomerOrders
        )
)
SELECT 
    co.c_custkey,
    co.c_name,
    sp.p_name,
    sp.total_available,
    hss.s_name AS supplier_name,
    hss.total_sales
FROM 
    CustomerOrders co
JOIN 
    SupplierParts sp ON co.order_count > 5
LEFT JOIN 
    HighSpenderSuppliers hss ON co.total_spent > 1000
WHERE 
    sp.avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    co.total_spent DESC, sp.total_available DESC;
