WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey, p.p_name
),
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
),
LineItemSummary AS (
    SELECT 
        lo.l_orderkey,
        COUNT(lo.l_linenumber) AS line_item_count,
        SUM(lo.l_extendedprice) AS total_line_item_price
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    spd.s_name,
    spd.p_name,
    spd.total_available_qty,
    spd.total_supply_cost,
    cod.c_name AS customer_name,
    cod.o_orderdate,
    lis.line_item_count,
    lis.total_line_item_price
FROM 
    SupplierPartDetails spd
JOIN 
    LineItemSummary lis ON spd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = spd.s_suppkey)
JOIN 
    CustomerOrderDetails cod ON lis.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cod.c_custkey)
ORDER BY 
    spd.s_name, cod.o_orderdate DESC
LIMIT 100;
