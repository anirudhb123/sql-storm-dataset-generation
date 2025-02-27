WITH NationSupplierData AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
),
OrderLineTotal AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
CombinedData AS (
    SELECT 
        ns.nation_name,
        ns.supplier_count,
        ns.avg_account_balance,
        olt.total_value
    FROM 
        NationSupplierData ns
    JOIN 
        OrderLineTotal olt ON ns.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = (SELECT DISTINCT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey IN (SELECT p_partkey FROM part WHERE p_brand = 'Brand#23'))))
)
)
SELECT 
    nation_name,
    supplier_count,
    avg_account_balance,
    COUNT(total_value) AS order_count,
    SUM(total_value) AS total_order_value,
    AVG(total_value) AS avg_order_value
FROM 
    CombinedData
GROUP BY 
    nation_name, supplier_count, avg_account_balance
ORDER BY 
    total_order_value DESC, avg_order_value DESC;
