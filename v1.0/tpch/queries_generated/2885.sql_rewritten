WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate <= '1997-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) 
            FROM supplier s2 
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
PartSupply AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    ps.total_available,
    ps.total_supply_cost,
    COALESCE(s.suppliers_count, 0) AS suppliers_count,
    o.o_orderdate,
    o.o_totalprice,
    RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
FROM 
    part p
LEFT JOIN 
    PartSupply ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN (
    SELECT 
        l.l_partkey, 
        COUNT(DISTINCT l.l_suppkey) AS suppliers_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
) s ON p.p_partkey = s.l_partkey
INNER JOIN 
    RankedOrders o ON o.o_orderkey = (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey = p.p_partkey 
        LIMIT 1
    )
WHERE 
    p.p_retailprice BETWEEN 100.00 AND 200.00
    AND p.p_size IS NOT NULL
ORDER BY 
    ps.total_supply_cost DESC, 
    o.o_totalprice DESC;