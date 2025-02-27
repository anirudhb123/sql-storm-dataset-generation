WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), TopSuppliers AS (
    SELECT 
        ps.ps_suppkey,
        SUM(l.l_extendedprice) AS total_supplycost
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(l.l_extendedprice) > (SELECT AVG(total_supplycost) FROM (SELECT SUM(l2.l_extendedprice) AS total_supplycost FROM partsupp ps2 JOIN lineitem l2 ON ps2.ps_partkey = l2.l_partkey GROUP BY ps2.ps_suppkey) AS AvgCosts)
), SupplierRanking AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        RANK() OVER (ORDER BY s.s_acctbal DESC) AS account_rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), OrderSum AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_sum
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    coalesce(o.o_orderkey, 0) AS order_identifier,
    s.s_name AS supplier_name,
    r.r_name AS region_name,
    CASE 
        WHEN s.s_acctbal >= 50000 THEN 'High Value'
        WHEN s.s_acctbal IS NULL THEN 'No Balance'
        ELSE 'Standard'
    END AS supplier_category,
    o.total_order_sum AS customer_order_sum,
    ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY total_order_sum DESC) AS order_rank,
    CASE 
        WHEN total_revenue > 1000000 THEN 'Platinum'
        ELSE 'Regular'
    END AS supplier_tier
FROM 
    RankedOrders o
JOIN 
    SupplierRanking s ON s.account_rank <= 10
JOIN 
    nation n ON n.n_nationkey = s.s_suppkey
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
JOIN 
    OrderSum os ON os.c_custkey = o.o_orderkey 
WHERE 
    o.total_revenue IS NOT NULL 
    OR s.s_acctbal = (SELECT MAX(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
ORDER BY 
    supplier_category, order_rank DESC, supplier_name;
