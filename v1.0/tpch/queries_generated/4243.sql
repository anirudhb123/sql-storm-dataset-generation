WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierCost AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
ProductData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown'
            ELSE CAST(p.p_size AS VARCHAR)
        END AS part_size,
        COALESCE(pc.product_category, 'General') AS category
    FROM 
        part p
    LEFT JOIN (
        SELECT 
            p_type AS product_type, 
            COUNT(*) AS product_count
        FROM 
            part
        GROUP BY 
            p_type
    ) pc ON p.p_type = pc.product_type
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
)
SELECT 
    pd.p_name,
    pd.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    MAX(o.o_orderdate) AS last_order_date,
    c.c_name AS customer_name,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    ProductData pd ON l.l_partkey = pd.p_partkey
JOIN 
    CustomerSummary c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    SupplierCost sc ON pd.p_partkey = sc.ps_partkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01' 
    AND l.l_returnflag = 'N'
GROUP BY 
    pd.p_name, pd.p_brand, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY 
    sales_rank, total_sales DESC;
