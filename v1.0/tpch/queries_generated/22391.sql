WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 25
    AND 
        p.p_comment IS NOT NULL
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
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
        d.c_name,
        d.r_name,
        CASE 
            WHEN o.o_orderstatus = 'F' THEN 'Finalized'
            ELSE 'Pending'
        END AS order_status
    FROM 
        orders o
    JOIN 
        customer d ON o.o_custkey = d.c_custkey
    JOIN 
        nation n ON d.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT 
    h.o_orderkey,
    h.o_totalprice,
    h.order_status,
    rp.p_name,
    rp.p_retailprice,
    ss.s_name,
    ss.total_supply_cost,
    ss.part_count
FROM 
    HighValueOrders h
LEFT JOIN 
    RankedParts rp ON h.o_orderkey % 10 = rp.price_rank
FULL OUTER JOIN 
    SupplierStats ss ON ss.total_supply_cost = (
        SELECT MAX(total_supply_cost) 
        FROM SupplierStats 
        WHERE part_count > 5
    )
WHERE 
    (rp.p_partkey IS NULL OR ss.part_count > 3) 
    AND h.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
ORDER BY 
    h.o_orderkey DESC, h.o_totalprice DESC;
