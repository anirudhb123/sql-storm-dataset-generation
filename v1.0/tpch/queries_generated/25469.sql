WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
PartStatistics AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
        AVG(ps.ps_supplycost) AS avg_supplycost, 
        SUM(ps.ps_availqty) AS total_available_quantity
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate,
        SUM(l.l_quantity * l.l_extendedprice) AS total_line_cost
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT 
    sd.s_name, 
    sd.nation_name, 
    ps.p_name, 
    ps.supplier_count, 
    ps.avg_supplycost, 
    ods.total_line_cost, 
    CASE 
        WHEN ods.o_totalprice > 100000 THEN 'High Value Order' 
        ELSE 'Standard Order' 
    END AS order_category
FROM 
    SupplierDetails sd
JOIN 
    PartStatistics ps ON sd.s_suppkey = ps.supplier_count
JOIN 
    OrderDetails ods ON ods.total_line_cost > 50000
ORDER BY 
    sd.nation_name, ps.avg_supplycost DESC, order_category;
