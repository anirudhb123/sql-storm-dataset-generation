
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost 
    FROM 
        supplier s 
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey 
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate 
    FROM 
        customer c 
    JOIN 
        orders o ON c.c_custkey = o.o_custkey 
    WHERE 
        o.o_orderstatus = 'F' 
        AND o.o_orderdate >= DATE '1997-01-01'
), LineItemSummary AS (
    SELECT 
        l.l_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_cost, 
        COUNT(*) AS line_item_count 
    FROM 
        lineitem l 
    GROUP BY 
        l.l_orderkey
)
SELECT 
    o.c_custkey, 
    o.c_name, 
    SUM(ls.total_line_cost) AS total_spent, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders, 
    sd.total_supply_cost 
FROM 
    CustomerOrders o 
JOIN 
    LineItemSummary ls ON o.o_orderkey = ls.l_orderkey 
JOIN 
    SupplierDetails sd ON sd.s_nationkey = (
        SELECT 
            n.n_nationkey 
        FROM 
            nation n 
        WHERE 
            n.n_nationkey = (
                SELECT 
                    c.c_nationkey 
                FROM 
                    customer c 
                WHERE 
                    c.c_custkey = o.c_custkey
            )
    )
GROUP BY 
    o.c_custkey, 
    o.c_name, 
    sd.total_supply_cost 
ORDER BY 
    total_spent DESC
LIMIT 10;
