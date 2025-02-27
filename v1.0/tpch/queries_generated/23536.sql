WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus <> 'F')
),
MonthlySales AS (
    SELECT 
        DATE_TRUNC('month', lo.l_shipdate) AS sale_month,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales
    FROM 
        lineitem lo
    GROUP BY 
        sale_month
),
SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        MIN(ps.ps_supplycost) AS min_cost,
        MAX(ps.ps_supplycost) AS max_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey,
        s.s_name
),
NationDetails AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        SUM(s.s_acctbal) IS NOT NULL
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 1
)

SELECT 
    d.n_name AS nation_name, 
    ps.total_available,
    ps.s_name AS supplier_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    ms.sale_month,
    ms.total_sales,
    pd.p_name,
    pd.avg_supply_cost
FROM 
    NationDetails d
JOIN 
    SupplierStats ps ON d.number_of_suppliers > 1
LEFT JOIN 
    RankedOrders o ON d.number_of_suppliers >= o.rn
FULL OUTER JOIN 
    MonthlySales ms ON DATE_TRUNC('month', o.o_orderdate) = ms.sale_month
JOIN 
    ProductDetails pd ON pd.supplier_count > 2
WHERE 
    (pd.avg_supply_cost IS NOT NULL OR ps.total_available > 100)
    AND (o.o_orderstatus = 'O' OR o.o_orderkey IS NULL)
ORDER BY 
    d.n_name, ps.total_available DESC, o.o_orderdate DESC;
