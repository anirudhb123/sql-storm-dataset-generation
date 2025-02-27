WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
), HighValueOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name AS nation_name
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
), SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        p.p_retailprice,
        pd.o_orderkey
    FROM
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem pd ON pd.l_partkey = ps.ps_partkey
    JOIN 
        HighValueOrders h ON pd.l_orderkey = h.o_orderkey
)
SELECT 
    h.nation_name,
    COUNT(s.s_name) AS supplier_count,
    AVG(p.p_retailprice) AS avg_retail_price,
    SUM(h.o_totalprice) AS total_sales
FROM 
    HighValueOrders h
JOIN 
    SupplierDetails s ON h.o_orderkey = s.o_orderkey
JOIN 
    part p ON s.ps_partkey = p.p_partkey
GROUP BY 
    h.nation_name
ORDER BY 
    total_sales DESC;
