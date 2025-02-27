WITH
    SupplierDetails AS (
        SELECT 
            s.s_suppkey, 
            s.s_name, 
            s.s_acctbal, 
            n.n_name AS nation_name,
            r.r_name AS region_name
        FROM 
            supplier s
        JOIN 
            nation n ON s.s_nationkey = n.n_nationkey
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey
        WHERE 
            s.s_acctbal > 1000
    ),
    ProductDetails AS (
        SELECT 
            p.p_partkey, 
            p.p_name, 
            p.p_retailprice,
            ps.ps_availqty
        FROM 
            part p
        JOIN 
            partsupp ps ON p.p_partkey = ps.ps_partkey
        WHERE 
            p.p_size BETWEEN 10 AND 20
    ),
    OrderSummary AS (
        SELECT 
            o.o_orderkey, 
            SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
        FROM 
            orders o
        JOIN 
            lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE 
            o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
        GROUP BY 
            o.o_orderkey
    )
SELECT 
    sd.nation_name,
    sd.region_name,
    pd.p_name,
    SUM(os.total_revenue) AS total_revenue
FROM 
    SupplierDetails sd
JOIN 
    ProductDetails pd ON pd.p_partkey IN (
        SELECT ps.ps_partkey
        FROM partsupp ps
        JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = sd.nation_name)
    )
JOIN 
    OrderSummary os ON os.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = pd.p_partkey
    )
GROUP BY 
    sd.nation_name, 
    sd.region_name, 
    pd.p_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
