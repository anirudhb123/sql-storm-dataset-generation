WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus
),
FilteredOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_custkey, 
        ro.total_revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 5
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        s.s_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        partsupp ps
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    f.o_orderkey, 
    f.o_custkey,
    COALESCE(SUM(sd.s_acctbal), 0) AS total_supplier_account_balance,
    COUNT(sd.s_partkey) AS num_suppliers,
    COUNT(DISTINCT sd.s_name) AS unique_supplier_names,
    MAX(sd.s_comment) AS last_supplier_comment
FROM 
    FilteredOrders f
LEFT JOIN 
    SupplierDetails sd ON sd.ps_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s 
                                WHERE s.s_acctbal > 0)
    )
GROUP BY 
    f.o_orderkey, 
    f.o_custkey
HAVING 
    total_supplier_account_balance > 1000 OR 
    num_suppliers > 3
ORDER BY 
    f.o_orderkey DESC;
