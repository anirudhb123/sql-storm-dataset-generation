WITH SupplierSummary AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_account_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
PartSupplierAnalysis AS (
    SELECT 
        ps_partkey,
        SUM(ps_supplycost * ps_availqty) AS total_supply_value
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
OrderSummary AS (
    SELECT 
        o_custkey,
        COUNT(o_orderkey) AS total_orders,
        SUM(o_totalprice) AS total_revenue
    FROM 
        orders
    WHERE 
        o_orderstatus = 'O'
    GROUP BY 
        o_custkey
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COALESCE(ss.total_suppliers, 0) AS number_of_suppliers,
    COALESCE(ss.total_account_balance, 0) AS total_balance,
    COALESCE(ps.total_supply_value, 0) AS supply_value,
    os.total_orders,
    os.total_revenue,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Orders'
        WHEN os.total_revenue <= 10000 THEN 'Low Revenue'
        ELSE 'High Revenue'
    END AS revenue_category
FROM 
    nation n
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    PartSupplierAnalysis ps ON ps.ps_partkey IN (
        SELECT p_partkey
        FROM part 
        WHERE p_size > 10
    )
LEFT JOIN 
    OrderSummary os ON n.n_nationkey = (
        SELECT c_nationkey 
        FROM customer 
        WHERE c_custkey = os.o_custkey
    )
ORDER BY 
    n.n_name, r.r_name;
