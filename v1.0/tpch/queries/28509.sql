WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name,
        n.n_name AS nation_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_mktsegment,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
),

FilteredOrders AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.o_orderkey,
        co.o_orderdate,
        SUM(ld.l_extendedprice * (1 - ld.l_discount)) AS total_revenue
    FROM 
        CustomerOrders co
    JOIN 
        lineitem ld ON co.o_orderkey = ld.l_orderkey
    GROUP BY 
        co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate
),

FinalBenchmark AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.p_brand,
        pd.p_retailprice,
        fo.c_name AS customer_name,
        fo.total_revenue,
        RANK() OVER (PARTITION BY pd.p_type ORDER BY fo.total_revenue DESC) as revenue_rank
    FROM 
        PartDetails pd
    JOIN 
        FilteredOrders fo ON pd.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = fo.o_orderkey LIMIT 1)
)

SELECT 
    f.p_partkey,
    f.p_name,
    f.p_brand,
    f.p_retailprice,
    f.customer_name,
    f.total_revenue,
    f.revenue_rank
FROM 
    FinalBenchmark f
WHERE 
    f.revenue_rank <= 10
ORDER BY 
    f.p_partkey, f.revenue_rank;
