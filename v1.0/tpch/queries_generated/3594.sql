WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
), 
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), 
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS line_item_count,
        l.l_returnflag
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_returnflag
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.o_orderpriority,
    COALESCE(ld.total_revenue, 0) AS total_revenue,
    ss.part_count,
    ss.total_supply_cost,
    ROUND(ss.total_supply_cost / NULLIF(ss.part_count, 0), 2) AS avg_supply_cost_per_part,
    CASE 
        WHEN r.o_orderpriority = '1-URGENT' THEN 'High Priority'
        WHEN r.o_orderpriority = '2-HIGH' THEN 'High Priority'
        ELSE 'Normal Priority' 
    END AS priority_category
FROM 
    RankedOrders r
LEFT JOIN 
    LineItemDetails ld ON r.o_orderkey = ld.l_orderkey
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey 
                                         FROM partsupp ps 
                                         JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
                                         WHERE l.l_orderkey = r.o_orderkey 
                                         LIMIT 1)
WHERE 
    r.order_rank <= 10
ORDER BY 
    r.o_orderdate DESC, r.o_totalprice DESC;
