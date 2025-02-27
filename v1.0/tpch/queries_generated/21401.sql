WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(month, -6, GETDATE())
),
CustomerInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unknown' 
            WHEN c.c_acctbal < 1000 THEN 'Low' 
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium' 
            ELSE 'High' 
        END AS acctbal_category
    FROM 
        customer c
),
NationSupplierStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ci.c_name,
    ci.acctbal_category,
    ros.o_orderkey,
    ros.o_totalprice,
    nss.n_name,
    nss.supplier_count,
    nss.total_supply_cost,
    COALESCE(nss.total_supply_cost, 0) AS adjusted_supply_cost,
    CASE 
        WHEN nss.total_supply_cost IS NULL THEN 'Supply data not available'
        ELSE 'Available'
    END AS supply_status,
    COUNT(line.l_orderkey) OVER (PARTITION BY nss.n_nationkey) AS order_count_per_nation,
    STRING_AGG(l.l_comment, '; ') WITHIN GROUP (ORDER BY l.l_orderkey) AS line_comments
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedOrders ros ON ci.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ros.o_orderkey)
LEFT JOIN 
    lineitem l ON ros.o_orderkey = l.l_orderkey
LEFT JOIN 
    NationSupplierStats nss ON ci.c_nationkey = nss.n_nationkey
WHERE 
    nss.supplier_count > 0
    AND nss.total_supply_cost IS NOT NULL
ORDER BY 
    ci.acctbal_category, ros.o_totalprice DESC;
