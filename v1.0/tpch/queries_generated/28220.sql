WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        CONCAT(s.s_name, ' (', s.s_acctbal, ')') AS supplier_info, 
        ps.ps_availqty, 
        ps.ps_supplycost, 
        p.p_comment
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
RegionNation AS (
    SELECT 
        n.n_name AS nation_name, 
        r.r_name AS region_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    p.p_name AS part_name, 
    p.supplier_info, 
    r.region_name, 
    c.customer_name, 
    o.o_orderdate, 
    o.o_totalprice,
    LENGTH(p.p_comment) AS comment_length,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
FROM 
    PartSupplierDetails p
JOIN 
    RegionNation r ON p.p_partkey % 10 = r.region_name % 10
JOIN 
    CustomerOrders o ON o.o_orderkey % 100 = p.p_partkey % 100
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    TRIM(p.p_name) LIKE 'Widget%'
ORDER BY 
    o.o_orderdate DESC, 
    p.p_name;
