
WITH SupplierSummary AS (
    SELECT 
        s_nationkey,
        COUNT(*) AS total_suppliers,
        SUM(s_acctbal) AS total_account_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
PartSuppSummary AS (
    SELECT 
        ps_partkey,
        SUM(ps_availqty) AS total_available_quantity,
        AVG(ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
OrderDetails AS (
    SELECT 
        o_custkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY SUM(l_extendedprice * (1 - l_discount)) DESC) AS revenue_rank
    FROM 
        orders
    JOIN 
        lineitem ON o_orderkey = l_orderkey
    GROUP BY 
        o_custkey
)
SELECT 
    n.n_name,
    r.r_name,
    COALESCE(ss.total_suppliers, 0) AS total_suppliers,
    COALESCE(pss.total_available_quantity, 0) AS total_available_quantity,
    od.total_revenue,
    od.revenue_rank
FROM 
    nation n
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    PartSuppSummary pss ON EXISTS (
        SELECT 1 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_brand = 'Brand#12' 
            AND p.p_size IN (10, 20)
        ) 
        AND ps.ps_suppkey IN (
            SELECT s.s_suppkey 
            FROM supplier s 
            WHERE s.s_nationkey = n.n_nationkey
        )
    )
LEFT JOIN 
    OrderDetails od ON n.n_nationkey = od.o_custkey
WHERE 
    n.n_nationkey IS NOT NULL
    AND r.r_name LIKE '%NAM%'
ORDER BY 
    total_revenue DESC, 
    n.n_name;
