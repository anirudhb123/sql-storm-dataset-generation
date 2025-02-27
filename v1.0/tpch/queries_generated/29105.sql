WITH SupplierParts AS (
    SELECT 
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        FOLDER AS CONCAT(p.p_name, ' from ', s.s_name) AS part_supplier_combo
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), RegionCustomers AS (
    SELECT 
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_name,
        c.c_address,
        c.c_phone
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linestatus) AS lineitem_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.region_name,
    rp.nation_name,
    rp.c_name,
    rp.c_address,
    COUNT(DISTINCT sp.part_supplier_combo) AS part_supplier_count,
    SUM(od.total_revenue) AS total_revenue,
    AVG(od.lineitem_count) AS avg_lineitems_per_order
FROM 
    RegionCustomers rp
LEFT JOIN 
    SupplierParts sp ON rp.c_nationkey IN 
        (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%land%')
LEFT JOIN 
    OrderDetails od ON rp.c_custkey IN 
        (SELECT DISTINCT o.o_custkey FROM orders o WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31')
GROUP BY 
    rp.region_name, rp.nation_name, rp.c_name, rp.c_address
HAVING 
    SUM(od.total_revenue) > 10000
ORDER BY 
    total_revenue DESC;
