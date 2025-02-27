WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_nationkey
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) AS order_seq
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 5000
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)

SELECT 
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    COALESCE(hvo.o_orderkey, 'N/A') AS order_key,
    COALESCE(hvo.o_totalprice, 0.00) AS total_price,
    COALESCE(rv.total_supply_cost, 0) AS total_cost,
    sd.part_count,
    sd.total_available_qty
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers rv ON n.n_nationkey = rv.s_suppkey
LEFT JOIN 
    HighValueOrders hvo ON rv.s_suppkey = hvo.o_custkey
LEFT JOIN 
    SupplierDetails sd ON rv.s_suppkey = sd.s_suppkey
WHERE 
    r.r_name IS NOT NULL 
    AND (s.s_name IS NOT NULL OR d.total_available_qty > 10) 
ORDER BY 
    region_name, supplier_name;
