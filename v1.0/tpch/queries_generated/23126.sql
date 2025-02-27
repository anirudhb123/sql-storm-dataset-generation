WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.supplier_rank = 1
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
),
SupplierCustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(tp.s_suppkey, 0) AS supplier_key
    FROM 
        customer c
    LEFT JOIN 
        TopSuppliers tp ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE 
        c.c_acctbal > 100
),
FinalReport AS (
    SELECT 
        OCI.c_custkey,
        OCI.c_name,
        OCI.supplier_key,
        OD.total_lines,
        OD.total_price,
        CASE 
            WHEN OD.total_price IS NULL THEN 'No Orders'
            WHEN OD.total_price > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END AS order_value_category
    FROM 
        SupplierCustomerInfo OCI
    LEFT JOIN 
        OrderDetails OD ON OCI.c_custkey = OD.o_orderkey
)
SELECT 
    r.cust_info,
    COALESCE(r.order_value_category, 'No Activity') AS status,
    COUNT(r.supplier_key) AS distinct_suppliers_count,
    SUM(r.total_price) AS grand_total
FROM 
    FinalReport r
GROUP BY 
    r.cust_info, r.order_value_category
ORDER BY 
    grand_total DESC
FETCH FIRST 10 ROWS ONLY;
