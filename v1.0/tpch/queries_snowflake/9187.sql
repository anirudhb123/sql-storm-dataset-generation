WITH OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_name AS supplier_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_name
),
FinalReport AS (
    SELECT 
        od.o_orderkey,
        od.customer_name,
        od.o_orderdate,
        od.total_line_value,
        spl.supplier_name,
        spl.total_supply_cost
    FROM 
        OrderDetails od
    JOIN 
        SupplierPartDetails spl ON od.o_orderkey = (SELECT MAX(o.o_orderkey) FROM orders o WHERE o.o_orderdate <= od.o_orderdate)
    WHERE 
        od.line_count > 5
    ORDER BY 
        od.o_orderdate DESC, od.total_line_value DESC
)
SELECT 
    *
FROM 
    FinalReport
LIMIT 100;