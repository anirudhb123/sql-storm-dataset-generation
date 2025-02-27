WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'F'
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS orders_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), ProductPerformance AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(l.l_orderkey) AS order_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ps.s_name,
    cs.c_name,
    po.p_name,
    po.total_quantity_sold,
    po.avg_price,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.rnk
FROM 
    SupplierDetails ps
FULL OUTER JOIN 
    CustomerSummary cs ON ps.parts_supplied = cs.orders_count
JOIN 
    ProductPerformance po ON ps.total_supply_cost > 1000
LEFT JOIN 
    RankedOrders ro ON cs.orders_count > 2 AND ro.o_orderkey = cs.c_custkey
WHERE 
    po.total_quantity_sold IS NOT NULL
    AND (cs.total_spent IS NULL OR cs.total_spent > 500)
ORDER BY 
    ro.rnk DESC, ps.s_name, cs.c_name;
