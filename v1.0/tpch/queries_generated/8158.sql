WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierDetails AS (
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
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    cs.c_name,
    cs.region_name,
    os.total_sales,
    sd.unique_suppliers,
    sd.total_supply_cost
FROM 
    OrderSummary os
JOIN 
    CustomerRegion cs ON cs.c_custkey = (
        SELECT 
            o.o_custkey 
        FROM 
            orders o 
        WHERE 
            o.o_orderkey = os.o_orderkey
    )
JOIN 
    SupplierDetails sd ON sd.unique_suppliers > 5
ORDER BY 
    os.total_sales DESC, 
    os.o_orderdate ASC
LIMIT 50;
