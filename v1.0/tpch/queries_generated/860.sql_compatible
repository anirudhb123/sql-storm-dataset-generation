
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01' AND l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(SUM(l.total_value), 0) AS total_lineitem_value,
    COALESCE(s.total_parts, 0) AS total_parts_from_supplier,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    CASE 
        WHEN o.o_totalprice > 1000 THEN 'High Value'
        WHEN o.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    RankedOrders o
LEFT JOIN 
    LineItemSummary l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierStats s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (
            SELECT l.l_partkey 
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey
        )
    )
WHERE 
    o.order_rank <= 10
GROUP BY 
    o.o_orderkey, o.o_orderdate, o.o_totalprice, s.total_parts, s.total_supply_cost
ORDER BY 
    o.o_orderdate DESC;
