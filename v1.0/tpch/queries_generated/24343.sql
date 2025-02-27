WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '2022-01-01' AND '2023-01-01'
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Insufficient Balance'
            WHEN s.s_acctbal < 5000 THEN 'Low Balance'
            ELSE 'Sufficient Balance' 
        END AS balance_status
    FROM 
        supplier s
), 
PartStatus AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_availqty,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_availqty) IS NOT NULL
)
SELECT 
    DISTINCT r.n_name AS nation_name,
    p.p_name AS part_name,
    COALESCE(sd.balance_status, 'Unknown') AS supplier_balance_status,
    po.o_orderkey,
    po.o_totalprice,
    po.o_orderdate,
    ps.total_availqty,
    ps.avg_supplycost
FROM 
    RankedOrders po 
JOIN 
    lineitem l ON po.o_orderkey = l.l_orderkey
LEFT JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    nation r ON r.n_nationkey = (
        SELECT 
            c.c_nationkey 
        FROM 
            customer c 
        WHERE 
            c.c_custkey = po.o_custkey
    )
WHERE 
    (po.o_totalprice > 10000 OR ps.total_availqty < 10)
    AND (ps.avg_supplycost BETWEEN 50 AND 150 OR ps.avg_supplycost IS NULL)
ORDER BY 
    r.n_name, po.o_orderdate DESC
LIMIT 100 OFFSET 10;
