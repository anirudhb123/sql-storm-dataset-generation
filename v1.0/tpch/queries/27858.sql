WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_address) AS address_length,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(CHAR_LENGTH(p.p_comment)) AS max_comment_length
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_container
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_line_items,
        SUM(l.l_extendedprice) AS total_amount,
        AVG(l.l_discount) AS avg_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name AS supplier_name,
    sd.region_name,
    ps.p_name AS part_name,
    ps.total_available_quantity,
    os.total_line_items,
    os.total_amount,
    os.avg_discount,
    sd.name_length,
    sd.address_length,
    sd.comment_length,
    ps.max_comment_length
FROM 
    SupplierDetails sd
JOIN 
    PartStats ps ON sd.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = ps.p_partkey LIMIT 1)
JOIN 
    OrderSummary os ON os.total_line_items > 5 AND os.total_amount > 1000
WHERE 
    sd.region_name LIKE '%East%'
ORDER BY 
    os.total_amount DESC, sd.s_name ASC;
