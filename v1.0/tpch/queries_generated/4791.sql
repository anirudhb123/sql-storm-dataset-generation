WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
SupplierOrderDetails AS (
    SELECT 
        hs.o_orderkey,
        hs.o_orderdate,
        hs.net_value,
        rs.s_name,
        rs.total_supply_value
    FROM 
        HighValueOrders hs
    LEFT JOIN 
        lineitem l ON hs.o_orderkey = l.l_orderkey
    LEFT JOIN 
        RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey
)
SELECT 
    sd.o_orderkey,
    sd.o_orderdate,
    sd.net_value,
    COALESCE(sd.s_name, 'No Supplier') AS supplier_name,
    sd.total_supply_value
FROM 
    SupplierOrderDetails sd
WHERE 
    sd.total_supply_value IS NOT NULL
ORDER BY 
    sd.net_value DESC, 
    sd.o_orderdate ASC
LIMIT 10;
