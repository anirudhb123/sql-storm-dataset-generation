WITH supplier_info AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_address,
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), product_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice < 100
), order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS items_count,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    si.s_name,
    si.nation_name,
    pi.p_name,
    pi.p_brand,
    os.total_sales,
    os.items_count,
    os.o_orderdate
FROM 
    supplier_info si
JOIN 
    product_info pi ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pi.p_partkey LIMIT 1)
JOIN 
    order_summary os ON si.s_suppkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = os.o_orderkey LIMIT 1)
ORDER BY 
    os.total_sales DESC, si.nation_name, pi.p_retailprice
LIMIT 100;