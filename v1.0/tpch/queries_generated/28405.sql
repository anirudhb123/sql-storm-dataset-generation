WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' ', n.n_name) AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), 
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        p.p_name || ' ' || p.p_brand AS part_brand_name
    FROM 
        part p
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        SUM(l.l_extendedprice) AS total_extended_price,
        AVG(l.l_discount) AS average_discount
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name
) 
SELECT 
    sd.supplier_nation,
    pd.part_brand_name,
    os.o_orderkey,
    os.o_orderdate,
    os.total_extended_price,
    os.average_discount,
    sd.s_acctbal,
    sd.s_comment
FROM 
    SupplierDetails sd
JOIN 
    PartDetails pd ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pd.p_partkey)
JOIN 
    OrderSummary os ON os.o_totalprice > 1000 AND os.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
ORDER BY 
    sd.supplier_nation, pd.part_brand_name, os.o_orderdate DESC;
