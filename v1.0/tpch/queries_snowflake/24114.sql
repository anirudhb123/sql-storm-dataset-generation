
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    COALESCE(NR.n_name, 'Unknown') AS nation_name,
    COALESCE(NR.r_name, 'Unknown Region') AS region_name,
    SUM(CASE 
            WHEN L.l_returnflag = 'R' THEN L.l_extendedprice * (1 - L.l_discount) 
            ELSE 0 
        END) AS returned_sales,
    COUNT(DISTINCT C.c_custkey) AS distinct_customers,
    R.total_supply_cost,
    R.s_name AS top_supplier,
    R.rnk
FROM 
    lineitem L
LEFT JOIN 
    orders O ON L.l_orderkey = O.o_orderkey
LEFT JOIN 
    customer C ON O.o_custkey = C.c_custkey
LEFT JOIN 
    RankedSuppliers R ON L.l_suppkey = R.s_suppkey 
FULL OUTER JOIN 
    NationRegion NR ON C.c_nationkey = NR.n_nationkey
WHERE 
    (O.o_orderstatus IN ('O', 'F') OR L.l_shipmode = 'AIR') 
    AND (C.c_acctbal IS NULL OR C.c_acctbal > 100.00 OR EXISTS (SELECT 1 FROM supplier s WHERE s.s_nationkey = C.c_nationkey AND s.s_acctbal > C.c_acctbal))
GROUP BY 
    NR.n_name, NR.r_name, R.s_name, R.total_supply_cost, R.rnk 
HAVING 
    SUM(CASE WHEN L.l_discount > 0.0 THEN L.l_quantity ELSE 0 END) > 1000
ORDER BY 
    returned_sales DESC, region_name ASC, distinct_customers DESC;
