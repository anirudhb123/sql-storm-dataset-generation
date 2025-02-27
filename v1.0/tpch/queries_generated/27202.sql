WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_brand
    FROM 
        part p
),
SupplierInfos AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
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
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        si.s_name,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM 
        SupplierInfos si
    JOIN 
        partsupp ps ON si.s_suppkey = ps.ps_suppkey
    GROUP BY 
        si.s_name
    ORDER BY 
        total_available_qty DESC
    LIMIT 5
)
SELECT 
    pd.p_name,
    pd.p_brand,
    pd.p_type,
    pd.p_retailprice,
    o.order_date,
    ts.s_name AS top_supplier,
    o.total_revenue
FROM 
    PartDetails pd
JOIN 
    OrderSummary o ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost < 100)
JOIN 
    TopSuppliers ts ON ts.total_available_qty > 50
WHERE 
    pd.rank_brand <= 10
ORDER BY 
    pd.p_retailprice DESC, o.total_revenue DESC;
