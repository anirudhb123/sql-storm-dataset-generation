WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
        AND c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = c.c_mktsegment)
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, p.p_partkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        sp.total_available,
        sp.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY p.p_retailprice DESC) AS part_price_rank
    FROM 
        part p
    LEFT JOIN 
        SupplierParts sp ON p.p_partkey = sp.p_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
)

SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    COALESCE(h.part_price_rank, 0) AS part_rank,
    h.p_name AS high_value_part_name,
    n.n_name AS supplier_nation
FROM 
    RankedOrders r
LEFT JOIN 
    lineitem l ON r.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierParts sp ON l.l_suppkey = sp.s_suppkey AND l.l_partkey = sp.p_partkey
LEFT JOIN 
    HighValueParts h ON sp.p_partkey = h.p_partkey
LEFT JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    h.p_partkey IS NOT NULL
    OR r.price_rank <= 10
ORDER BY 
    r.o_orderdate ASC, r.o_totalprice DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM orders) / 2
UNION ALL
SELECT 
    DISTINCT NULL AS o_orderkey,
    NULL AS o_orderdate,
    NULL AS o_totalprice,
    NULL AS part_rank,
    NULL AS high_value_part_name,
    n.n_name
FROM 
    nation n
WHERE 
    n.n_nationkey NOT IN (SELECT DISTINCT s.s_nationkey FROM supplier s)
ORDER BY 
    1;
