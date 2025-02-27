WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        NULL AS s_name,
        NULL AS s_acctbal,
        NULL AS s_nationkey,
        level + 1
    FROM 
        SupplierHierarchy sh
    JOIN 
        partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    WHERE 
        level < 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
NationSales AS (
    SELECT 
        n.n_name,
        SUM(os.total_sales) AS region_sales
    FROM 
        nation n
    LEFT JOIN 
        orders o ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    GROUP BY 
        n.n_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        AVG(s.s_acctbal) AS avg_supplier_acctbal
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        p.p_size < 30
    GROUP BY 
        p.p_partkey
),
FinalReport AS (
    SELECT 
        n.n_name,
        COUNT(fp.p_partkey) AS part_count,
        SUM(fp.order_count) AS total_orders,
        RANK() OVER (ORDER BY SUM(fp.order_count) DESC) AS sales_rank
    FROM 
        NationSales n
    JOIN 
        FilteredParts fp ON n.n_name = (SELECT DISTINCT n2.n_name FROM nation n2 WHERE n2.n_nationkey = fp.p_partkey) 
    GROUP BY 
        n.n_name
)
SELECT 
    rp.n_name,
    rp.part_count,
    rp.total_orders,
    EXISTS (SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = rp.n_nationkey) AS has_high_balance_suppliers
FROM 
    FinalReport rp
WHERE 
    rp.sales_rank <= 10
ORDER BY 
    rp.total_orders DESC;
