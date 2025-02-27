WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rnk <= 3
),
RelevantNationInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        orders o ON s.s_suppkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        (ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
),
AggregateCustomerData AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name,
    n.order_count,
    COALESCE(ts.s_name, 'No Supplier') AS top_supplier,
    COALESCE(ts.s_acctbal, 0) AS supplier_balance,
    COALESCE(ac.total_spent, 0) AS customer_spent,
    CASE
        WHEN n.order_count > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS nation_activity,
    STRING_AGG(DISTINCT CONCAT(pd.p_name, ' (', pd.total_cost, ')'), ', ') AS parts_details
FROM 
    RelevantNationInfo n
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_suppkey
LEFT JOIN 
    AggregateCustomerData ac ON n.n_nationkey = ac.c_nationkey
LEFT JOIN 
    PartSupplierDetails pd ON pd.p_partkey = (SELECT MAX(p_partkey) FROM part)
GROUP BY 
    n.n_name, n.order_count, ts.s_name, ts.s_acctbal, ac.total_spent
HAVING 
    n.order_count < (SELECT COUNT(*) FROM nation) AND 
    (COALESCE(ac.total_spent, 0) > 1000 OR ts.s_acctbal IS NULL)
ORDER BY 
    n.order_count DESC, ts.s_acctbal ASC;
