WITH OrderedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_type,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderdate,
        l.l_quantity,
        l.l_extendedprice,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        p.p_name LIKE '%widget%'
),
AggregatedData AS (
    SELECT 
        supplier_name,
        COUNT(DISTINCT o_orderkey) AS num_orders,
        SUM(l_quantity) AS total_quantity,
        AVG(ps_supplycost) AS avg_supply_cost,
        STRING_AGG(short_comment, ', ') AS comments_summary
    FROM 
        OrderedParts
    GROUP BY 
        supplier_name
)
SELECT 
    supplier_name,
    num_orders,
    total_quantity,
    ROUND(avg_supply_cost, 2) AS avg_supply_cost,
    comments_summary
FROM 
    AggregatedData
ORDER BY 
    num_orders DESC, total_quantity DESC;
