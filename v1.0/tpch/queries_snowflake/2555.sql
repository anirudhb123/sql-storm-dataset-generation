WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate > '1997-01-01'
),
CustomerRanks AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_within_segment
    FROM 
        customer c
)

SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(s.total_cost, 0) AS supplier_total_cost,
    COALESCE(h.o_totalprice, 0) AS highest_order_value,
    r.r_name
FROM 
    customer c
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    SupplierStats s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_size = (
                SELECT MAX(p2.p_size) 
                FROM part p2
            )
        ) 
        LIMIT 1
    )
LEFT JOIN 
    HighValueOrders h ON h.o_orderkey = (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = c.c_custkey 
        ORDER BY o.o_totalprice DESC 
        LIMIT 1
    )
WHERE 
    c.c_acctbal IS NOT NULL
AND 
    r.r_name LIKE 'N%'
ORDER BY 
    c.c_acctbal DESC, supplier_total_cost DESC;