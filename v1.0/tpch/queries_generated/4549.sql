WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(l.l_linenumber) AS number_of_items
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= DATE '2022-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    c.c_name AS customer_name,
    COALESCE(ss.total_parts_supplied, 0) AS total_parts,
    COALESCE(ss.total_supply_cost, 0) AS total_cost,
    li.total_value AS line_item_value,
    li.number_of_items,
    o.order_rank
FROM 
    RankedOrders o
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            lineitem l ON ps.ps_partkey = l.l_partkey 
        WHERE 
            l.l_orderkey = o.o_orderkey
        LIMIT 1
    )
LEFT JOIN 
    LineItemSummary li ON li.l_orderkey = o.o_orderkey
WHERE 
    o.order_rank <= 5
ORDER BY 
    o.o_totalprice DESC;
