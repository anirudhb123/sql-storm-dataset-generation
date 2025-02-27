WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        SUM(l.l_discount) AS total_discounted_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
),
Result AS (
    SELECT 
        pi.p_partkey,
        pi.p_name,
        pi.p_brand,
        pi.region_name,
        pi.nation_name,
        pi.supplier_name,
        os.o_orderkey,
        os.o_orderdate,
        os.o_orderstatus,
        os.line_count,
        os.total_extended_price,
        os.total_discounted_price
    FROM 
        PartInfo pi
    LEFT JOIN 
        OrderStats os ON pi.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = pi.ps_supplycost LIMIT 1)
)
SELECT 
    CONCAT('Part: ', p_name, ', Brand: ', p_brand, ', Supplied by: ', supplier_name, 
           ', Ordered on: ', TO_CHAR(o_orderdate, 'YYYY-MM-DD'), 
           ', Order Status: ', o_orderstatus, 
           ', Line Count: ', line_count, 
           ', Total Extended Price: $', ROUND(total_extended_price, 2), 
           ', Discounted Price: $', ROUND(total_discounted_price, 2)) AS Query_Result
FROM 
    Result
WHERE 
    (os.o_orderstatus IN ('O', 'F') AND line_count > 2)
ORDER BY 
    o_orderdate DESC;
