WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        n.n_regionkey,
        COALESCE(n.n_name, 'Unknown') AS region_name
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
),
PartCounts AS (
    SELECT 
        ps.ps_partkey,
        COUNT(ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    pr.region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    SUM(l.l_extendedprice - l.l_discount) AS net_revenue,
    AVG(s.s_acctbal) FILTER (WHERE s.s_acctbal IS NOT NULL) AS avg_supplier_balance,
    ps.supplier_count,
    CASE 
        WHEN p.p_retailprice = 0 THEN 'Free'
        WHEN p.p_retailprice IS NULL THEN 'Price Unknown'
        ELSE 'Priced'
    END AS price_status
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    HighValueOrders hvo ON l.l_orderkey = hvo.o_orderkey
LEFT JOIN 
    RankedSuppliers s ON s.rank <= 3 AND s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN 
    CustomerRegion pr ON pr.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = hvo.o_custkey)
LEFT JOIN 
    PartCounts ps ON ps.ps_partkey = p.p_partkey
GROUP BY 
    p.p_partkey, p.p_name, pr.region_name, ps.supplier_count
ORDER BY 
    net_revenue DESC, order_count ASC;
