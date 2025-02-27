WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2022-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT o.o_orderkey) AS high_value_count
    FROM 
        RankedOrders r
    LEFT JOIN 
        customer c ON r.o_orderkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.order_rank <= 10 
        AND r.o_orderstatus = 'F'
    GROUP BY 
        r.r_name
)
SELECT 
    s.s_suppkey,
    COALESCE(ss.total_supply_value, 0) AS total_supply_value,
    COALESCE(ss.distinct_parts, 0) AS distinct_parts,
    hvo.high_value_count
FROM 
    SupplierStats ss
FULL OUTER JOIN 
    HighValueOrders hvo ON hvo.r_name = (
        SELECT r.r_name 
        FROM region r 
        WHERE r.r_regionkey = (
            SELECT n.n_regionkey 
            FROM nation n 
            WHERE n.n_nationkey = (
                SELECT c.c_nationkey 
                FROM customer c 
                WHERE c.c_custkey = ss.s_suppkey
            )
        )
    )
ORDER BY 
    total_supply_value DESC NULLS LAST, 
    distinct_parts ASC;
