WITH RecursivePart AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p_brand ORDER BY p_retailprice DESC) AS rn
    FROM 
        part
), 
SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS unique_suppliers,
        SUM(s_acctbal) AS total_acctbal,
        AVG(s_acctbal) AS avg_acctbal
    FROM 
        supplier
    GROUP BY 
        s_nationkey
), 
OrderDetails AS (
    SELECT 
        o_orderkey,
        o_custkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_price,
        COUNT(l_orderkey) AS line_count,
        MAX(l_shipdate) AS latest_shipdate
    FROM 
        orders 
    JOIN 
        lineitem ON o_orderkey = l_orderkey
    GROUP BY 
        o_orderkey, o_custkey
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(os.total_price) AS avg_order_value,
    COALESCE(SUM(ps.ps_supplycost * rp.p_retailprice), 0) AS total_cost,
    STRING_AGG(DISTINCT rp.p_name, ', ') AS part_names,
    COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
    r.r_name AS region,
    CASE 
        WHEN COUNT(DISTINCT s.s_suppkey) > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS supplier_status
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    OrderDetails os ON c.c_custkey = os.o_custkey
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = n.n_nationkey)
LEFT JOIN 
    RecursivePart rp ON ps.ps_partkey = rp.p_partkey AND rp.rn <= 5
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    n.n_name IS NOT NULL 
    AND (avg_order_value IS NULL OR avg_order_value > 100)
GROUP BY 
    n.n_name, r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_cost DESC NULLS LAST;
