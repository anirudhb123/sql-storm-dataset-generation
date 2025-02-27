WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) 
            FROM part p2 
            WHERE p2.p_size BETWEEN 1 AND 50
        )
),
SupplierAgg AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(s.s_acctbal) AS total_account_balance
    FROM 
        supplier s
    GROUP BY 
        s.s_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized' 
            ELSE 'Pending' 
        END AS order_status
    FROM 
        orders o
    WHERE 
        o.o_totalprice > 1000
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_price,
        COUNT(*) AS line_count
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(lid.net_price) AS total_net_price,
    SUM(COALESCE(sagg.total_account_balance, 0)) AS total_supplier_balance,
    STRING_AGG(DISTINCT pp.p_name, ', ') AS popular_parts
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    OrderStats o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    LineItemDetails lid ON o.o_orderkey = lid.l_orderkey
LEFT JOIN 
    SupplierAgg sagg ON n.n_nationkey = sagg.s_nationkey
LEFT JOIN 
    RankedParts pp ON pp.p_partkey = ANY (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_supplycost < (SELECT MAX(ps2.ps_supplycost) FROM partsupp ps2)
    )
WHERE 
    r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_net_price DESC
LIMIT 10;
