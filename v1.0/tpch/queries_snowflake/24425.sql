WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'O'
        AND o.o_totalprice IS NOT NULL
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
PartAnalysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COALESCE(MAX(ps.ps_supplycost), 0) AS max_supply_cost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
HighValueOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        pd.p_partkey,
        pd.supplier_count,
        pd.avg_supply_cost
    FROM 
        RankedOrders ro
    CROSS JOIN 
        PartAnalysis pd
    WHERE 
        ro.order_rank = 1
        AND pd.supplier_count > 5
)
SELECT 
    hvo.o_orderkey,
    hvo.o_orderdate,
    hvo.o_totalprice,
    p.p_name,
    sd.s_name,
    hvo.avg_supply_cost,
    hvo.supplier_count
FROM 
    HighValueOrders hvo
INNER JOIN 
    SupplierDetails sd ON sd.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierDetails)
INNER JOIN 
    part p ON hvo.p_partkey = p.p_partkey
LEFT JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = hvo.o_orderkey % 100) 
WHERE 
    p.p_size IS NOT NULL 
    AND (hvo.o_totalprice - COALESCE(sd.total_supply_cost, 0)) > 100 
    AND n.n_name IS NULL
ORDER BY 
    hvo.o_totalprice DESC 
LIMIT 10;
