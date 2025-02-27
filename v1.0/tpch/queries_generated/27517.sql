WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name,
        CONCAT(s.s_name, ' | ', n.n_name, ' | ', r.r_name) AS supplier_full_name
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
        CONCAT(p.p_name, ' | ', p.p_brand, ' | ', p.p_type) AS part_full_name
    FROM 
        part p
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        SUM(l.l_discount) AS total_discount
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_totalprice, o.o_orderdate
)
SELECT 
    sd.supplier_full_name,
    pd.part_full_name,
    os.c_name,
    os.o_orderdate,
    os.total_extended_price,
    os.total_discount
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderStats os ON os.o_orderkey IN (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = pd.p_partkey AND l.l_suppkey = sd.s_suppkey
    )
WHERE 
    os.total_extended_price > 1000
ORDER BY 
    sd.supplier_full_name, pd.part_full_name;
