WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        CTE_SupplierInfo.s_name,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS net_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    LEFT JOIN (
        SELECT 
            ps.ps_partkey, 
            s.s_suppkey,
            s.s_name
        FROM 
            partsupp ps
        JOIN 
            supplier s ON ps.ps_suppkey = s.s_suppkey
        WHERE 
            ps.ps_supplycost > 100
    ) AS CTE_SupplierInfo ON li.l_partkey = CTE_SupplierInfo.ps_partkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, CTE_SupplierInfo.s_name, o.o_custkey
), 
CustomerBalances AS (
    SELECT 
        c.c_custkey,
        c.c_acctbal,
        CASE 
            WHEN c.c_acctbal IS NULL THEN 'Unspecified'
            WHEN c.c_acctbal < 100 THEN 'Low Balance'
            ELSE 'Sufficient Balance'
        END AS balance_status
    FROM 
        customer c
)
SELECT 
    e.n_name AS nation_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    COALESCE(o.s_name, 'Unknown Supplier') AS supplier_name,
    o.net_revenue,
    cb.balance_status
FROM 
    RankedOrders o
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation e ON c.c_nationkey = e.n_nationkey
LEFT JOIN 
    CustomerBalances cb ON c.c_custkey = cb.c_custkey
WHERE 
    o.net_revenue > 1000 
    AND (o.o_orderdate BETWEEN '2022-01-01' AND CURRENT_DATE)
    AND (cb.balance_status IS NOT NULL OR cb.balance_status != 'Low Balance')
UNION ALL
SELECT 
    e.n_name,
    NULL AS o_orderkey,
    NULL AS o_orderdate,
    NULL AS o_totalprice,
    NULL AS supplier_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
    'Aggregated Cost' AS balance_status
FROM 
    partsupp ps
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation e ON s.s_nationkey = e.n_nationkey
WHERE 
    ps.ps_availqty < 50
GROUP BY 
    e.n_name
ORDER BY 
    nation_name, o_orderdate DESC NULLS LAST;
