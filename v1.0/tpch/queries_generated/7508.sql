WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ps.ps_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_nationkey,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        l.l_lineitemkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
), 
NationStatistics AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_sales
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT
    r.r_name AS region_name,
    ns.n_name AS nation_name,
    ns.customer_count,
    ns.total_sales,
    spd.s_name AS supplier_name,
    spd.p_name AS part_name,
    spd.p_brand,
    SUM(spd.ps_availqty) AS total_available_quantity,
    AVG(spd.ps_supplycost) AS avg_supply_cost
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    NationStatistics ns ON n.n_nationkey = ns.n_nationkey
JOIN 
    SupplierPartDetails spd ON n.n_nationkey = spd.s_nationkey
GROUP BY 
    r.r_name, ns.n_name, ns.customer_count, ns.total_sales, spd.s_name, spd.p_name, spd.p_brand
ORDER BY 
    region_name, nation_name, supplier_name;
