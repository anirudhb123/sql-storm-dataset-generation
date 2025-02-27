WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown'
            WHEN s.s_acctbal < 0 THEN 'Negative Balance'
            ELSE 'Valid Account' 
        END AS account_status
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00 OR s.s_comment LIKE '%reliable%'
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost,
        MAX(p.p_retailprice) AS max_price,
        COALESCE(STRING_AGG(DISTINCT p.p_name, ', '), 'No Parts') AS part_names
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
)
SELECT 
    p.p_partkey,
    p.part_names,
    p.suppliers_count,
    p.total_cost,
    r.o_orderkey,
    r.o_totalprice,
    r.o_orderdate,
    fs.s_name,
    fs.account_status
FROM 
    PartDetails p
LEFT JOIN 
    RankedOrders r ON r.order_rank = 1
LEFT JOIN 
    FilteredSuppliers fs ON p.suppliers_count > 0 AND p.p_partkey = fs.s_suppkey
WHERE 
    (p.total_cost IS NOT NULL OR p.suppliers_count > 2)
    AND (r.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31' OR r.o_orderdate IS NULL)
ORDER BY 
    p.total_cost DESC NULLS LAST, 
    r.o_totalprice ASC NULLS FIRST;
