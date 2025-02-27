WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rank_acctbal
    FROM 
        supplier s
),
MaxPartPrice AS (
    SELECT 
        MAX(p.p_retailprice) AS max_price,
        p.p_mfgr
    FROM 
        part p
    GROUP BY 
        p.p_mfgr
),
FilterOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate < DATE '2023-01-01'
        AND o.o_orderstatus IN ('O', 'F')
),
EligibleLineItems AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT 
                AVG(SUM(l2.l_extendedprice * (1 - l2.l_discount))) 
            FROM 
                lineitem l2
            GROUP BY 
                l2.l_orderkey
        )
)
SELECT 
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    ps.ps_partkey,
    COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_discount) AS avg_discount,
    (SELECT 
        COUNT(*) 
     FROM 
        FilterOrders fo 
     WHERE 
        fo.o_orderkey IN (SELECT DISTINCT l.l_orderkey FROM lineitem l WHERE l.l_suppkey = ps.ps_suppkey)
    ) AS order_count,
    MAX(m.max_price) AS max_price_per_mfgr
FROM 
    partsupp ps
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    EligibleLineItems eli ON eli.l_orderkey = ps.ps_partkey
LEFT JOIN 
    MaxPartPrice m ON m.p_mfgr = s.s_name
WHERE 
    ps.ps_availqty > 0
GROUP BY 
    n.n_name, ps.ps_partkey
HAVING 
    unique_suppliers > (
        SELECT 
            COUNT(*) / 10 
        FROM 
            RankedSuppliers 
        WHERE 
            rank_acctbal <= 5
            AND s_nationkey = s.s_nationkey
    )
ORDER BY 
    unique_suppliers DESC, total_quantity DESC;
