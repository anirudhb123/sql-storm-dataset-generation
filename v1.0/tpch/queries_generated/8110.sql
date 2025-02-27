WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
), 
RegionNationSupplier AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
)
SELECT 
    rns.region_name,
    rns.nation_name,
    rns.supplier_name,
    psd.p_name,
    SUM(psd.ps_availqty) AS total_available_quantity,
    AVG(psd.ps_supplycost) AS avg_supply_cost,
    MAX(cos.total_extended_price) AS max_order_value,
    COUNT(cos.o_orderkey) AS total_orders,
    AVG(cos.lineitem_count) AS avg_lineitems_per_order
FROM 
    SupplierPartDetails psd
JOIN 
    RegionNationSupplier rns ON psd.s_suppkey IN (SELECT s.s_suppkey FROM supplier s)
JOIN 
    CustomerOrderSummary cos ON psd.s_suppkey IN (SELECT s.s_suppkey FROM supplier s JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey JOIN part p ON ps.ps_partkey = p.p_partkey)
GROUP BY 
    rns.region_name,
    rns.nation_name,
    rns.supplier_name,
    psd.p_name
ORDER BY 
    total_available_quantity DESC, avg_supply_cost ASC;
