WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank_per_brand
    FROM 
        part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) OVER (PARTITION BY c.c_custkey) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
    AVG(ps.total_supply_cost) AS avg_supply_cost,
    COUNT(DISTINCT rp.p_partkey) AS distinct_parts_ranked,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderstatus = 'O' AND o.o_totalprice BETWEEN 100 AND 1000) AS open_order_count
FROM 
    lineitem l
LEFT JOIN 
    customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN 
    RankedParts rp ON l.l_partkey = rp.p_partkey AND rp.rank_per_brand <= 10
LEFT JOIN 
    SupplierDetails ps ON l.l_suppkey = ps.s_suppkey
WHERE 
    l.l_shipdate > '2022-01-01' AND (l.l_discount IS NULL OR l.l_discount > 0.1)
GROUP BY 
    c.c_custkey
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000 OR COUNT(DISTINCT rp.p_partkey) > 5
ORDER BY 
    net_revenue DESC, avg_supply_cost ASC;
