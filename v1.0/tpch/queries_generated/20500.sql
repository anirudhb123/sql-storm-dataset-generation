WITH regional_data AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        region r
    LEFT JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
part_supplier_data AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
high_value_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_totalprice, o.o_orderdate
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    r.r_name,
    pd.p_name,
    pd.ps_availqty,
    pd.ps_supplycost,
    (((pd.ps_supplycost * 1.2) - pd.ps_supplycost) / NULLIF(pd.ps_supplycost, 0)) * 100) AS markup_percentage,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    d.total_acctbal,
    CASE 
        WHEN MAX(pd.ps_supplycost) IS NULL THEN 'No Supplier'
        ELSE 'Supplier Available'
    END AS supplier_status
FROM 
    regional_data r
LEFT JOIN 
    part_supplier_data pd ON r.nation_count > 2 AND pd.rn = 1
LEFT JOIN 
    high_value_orders o ON pd.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_availqty > 0)
GROUP BY 
    r.r_name, pd.p_name, pd.ps_availqty, pd.ps_supplycost, o.o_orderkey, o.o_orderdate, o.o_totalprice, d.total_acctbal
HAVING 
    ROUND(AVG(o.o_totalprice), 2) BETWEEN 100 AND 500
ORDER BY 
    r.r_name, pd.ps_supplycost DESC, o.o_orderdate DESC;
