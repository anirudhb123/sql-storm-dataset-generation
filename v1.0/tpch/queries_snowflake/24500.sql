
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN (SELECT AVG(ps_supplycost) FROM partsupp) AND (SELECT AVG(ps_supplycost) + 10 FROM partsupp)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS supplier_nation,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts,
        MIN(l.l_shipdate) AS first_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        os.total_revenue,
        CASE 
            WHEN os.total_revenue > 1000 THEN 'High'
            ELSE 'Low'
        END AS order_value
    FROM 
        OrderSummary os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    WHERE 
        os.total_revenue IS NOT NULL
)
SELECT 
    hp.p_name,
    hp.p_brand,
    sd.s_name,
    dv.order_value,
    dv.total_revenue,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0) AS return_quantity,
    COUNT(DISTINCT cd.c_custkey) AS customer_count,
    MAX(hp.rn) AS max_ranked_part
FROM 
    RankedParts hp
LEFT JOIN 
    partsupp ps ON hp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey AND sd.supp_rank = 1
LEFT JOIN 
    HighValueOrders dv ON dv.o_orderkey = dv.o_orderkey
LEFT JOIN 
    customer cd ON cd.c_custkey = cd.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = dv.o_orderkey
GROUP BY 
    hp.p_name, hp.p_brand, sd.s_name, dv.order_value, dv.total_revenue
HAVING 
    COUNT(DISTINCT cd.c_custkey) > 5
ORDER BY 
    hp.p_brand, total_revenue DESC;
