WITH SupplierData AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_available_qty DESC
    LIMIT 10
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.nation_name, 
    p.p_name AS top_part_name, 
    os.o_orderkey, 
    os.total_revenue
FROM 
    SupplierData sd
JOIN 
    TopParts p ON sd.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
ORDER BY 
    sd.nation_name, os.total_revenue DESC;