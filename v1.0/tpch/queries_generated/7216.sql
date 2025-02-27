WITH SupplierPartCounts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
NationSupplierData AS (
    SELECT 
        n.n_name,
        n.n_nationkey,
        spc.s_suppkey,
        spc.s_name,
        spc.part_count,
        spc.total_supply_value
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        SupplierPartCounts spc ON s.s_suppkey = spc.s_suppkey
), 
OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), 
DetailedInvoice AS (
    SELECT 
        nsd.n_name,
        os.c_name,
        os.total_order_value,
        os.order_count,
        ns.s_name AS supplier_name,
        ns.part_count,
        ns.total_supply_value
    FROM 
        NationSupplierData ns
    JOIN 
        OrderSummary os ON ns.n_nationkey = os.c_nationkey
)
SELECT 
    d.n_name AS nation,
    d.c_name AS customer,
    d.total_order_value,
    d.order_count,
    d.supplier_name,
    d.part_count,
    d.total_supply_value,
    (d.total_order_value / d.order_count) AS average_order_value
FROM 
    DetailedInvoice d
WHERE 
    d.total_order_value > 10000
ORDER BY 
    d.total_order_value DESC, d.n_name, d.c_name;
