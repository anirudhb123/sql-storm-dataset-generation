WITH CustomerSummary AS (
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
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    cs.c_name,
    cs.total_spent,
    COALESCE(spd.total_supply_cost, 0) AS total_supply_cost,
    ol.total_revenue,
    ol.line_item_count
FROM 
    CustomerSummary cs
LEFT JOIN 
    SupplierPartDetails spd ON cs.c_custkey = (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_discount > 0))
LEFT JOIN 
    OrderLineDetails ol ON ol.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC
LIMIT 10;
