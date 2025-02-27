WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers,
        MAX(l.l_shipdate) AS latest_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplier_cost,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey
)
SELECT 
    os.o_orderkey,
    os.total_revenue,
    os.unique_suppliers,
    os.latest_ship_date,
    sd.s_suppkey,
    sd.total_supplier_cost
FROM 
    OrderSummary os
JOIN 
    SupplierDetails sd ON sd.rn = 1
WHERE 
    sd.total_supplier_cost > 10000
ORDER BY 
    os.total_revenue DESC
LIMIT 50;
