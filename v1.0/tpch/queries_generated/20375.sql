WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank 
    FROM 
        part p 
    WHERE 
        p.p_retailprice IS NOT NULL
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
TopSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_qty,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 100
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
        AND (l.l_discount IS NULL OR l.l_discount < 0.10)
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(DISTINCT lp.l_extendedprice) AS total_lineitem_revenue,
    AVG(n.supremely_high_acctbal) OVER (PARTITION BY n.n_nationkey) AS avg_acctbal,
    COALESCE(MAX(p.p_name), 'No Parts') AS most_expensive_part,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 0 THEN 'Active Customers'
        ELSE 'Inactive Customers' 
    END AS customer_status,
    string_agg(DISTINCT ps.ps_partkey::text, ', ') AS supplied_partkeys
FROM 
    NationStats n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    TopSuppliers ps ON ps.ps_suppkey = n.supplier_count
LEFT JOIN 
    FilteredOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    RankedParts p ON ps.ps_partkey = p.p_partkey AND p.rank = 1
LEFT JOIN 
    lineitem lp ON lp.l_orderkey = o.o_orderkey
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
    OR EXISTS (SELECT 1 FROM partsupp WHERE ps_availqty < 5);
