WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE()) 
          AND o.o_orderstatus IN ('O', 'F')
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost) > 50000
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 3
),
ProductAnalysis AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity,
        AVG(l.l_discount) AS avg_discount,
        MAX(l.l_extendedprice) AS max_price
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_returnflag = 'N' 
          AND l.l_shipmode IN ('AIR', 'GROUND')
    GROUP BY 
        p.p_partkey
    HAVING 
        COUNT(l.l_linenumber) > 2
)
SELECT 
    r.r_name,
    cs.c_custkey,
    cs.order_count,
    cs.total_spent,
    RANK() OVER (PARTITION BY r.r_name ORDER BY cs.total_spent DESC) AS customer_rank,
    pa.total_quantity,
    pa.avg_discount,
    sd.total_supply_cost
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
JOIN 
    CustomerStats cs ON cs.order_count > 5
LEFT JOIN 
    ProductAnalysis pa ON cs.order_count = pa.total_quantity
WHERE 
    r.r_comment NOT LIKE '%obsolete%'
    AND (sd.total_supply_cost IS NULL OR sd.total_supply_cost > 60000)
ORDER BY 
    r.r_name, customer_rank;
