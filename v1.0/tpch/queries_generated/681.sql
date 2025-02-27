WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank_by_spending
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), 

LineItemAggregates AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_revenue,
        COUNT(l.l_linenumber) AS line_item_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
) 

SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.order_count,
    cs.total_spent,
    ss.total_avail_qty,
    ss.total_supply_cost,
    la.total_line_revenue,
    la.line_item_count
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.rank_by_spending <= 5
LEFT JOIN 
    LineItemAggregates la ON cs.order_count > 0
WHERE 
    cs.order_count > 0 OR ss.total_supply_cost IS NULL
ORDER BY 
    cs.total_spent DESC, cs.c_name ASC;
