WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        CONCAT(s.s_address, ', ', n.n_name) AS full_address,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartNames AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%metal%'
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.s_suppkey,
    sd.s_name,
    sd.full_address,
    p.p_partkey,
    p.p_name,
    os.total_sales,
    RANK() OVER (PARTITION BY sd.nation_name ORDER BY os.total_sales DESC) AS sales_rank
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartNames p ON ps.ps_partkey = p.p_partkey
JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE 
    sd.s_acctbal > 1000
ORDER BY 
    sd.nation_name, sales_rank;
