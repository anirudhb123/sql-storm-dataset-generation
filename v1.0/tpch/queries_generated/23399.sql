WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_by_balance
    FROM 
        supplier s
),
MaxPartPrice AS (
    SELECT 
        MAX(p.p_retailprice) AS max_price
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
),
JoinedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(DISTINCT li.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'P') 
        AND li.l_shipdate IS NOT NULL 
        AND (li.l_returnflag IS NULL OR li.l_returnflag <> 'R')
    GROUP BY 
        o.o_orderkey
),
SupplierDetails AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    p.p_name,
    p.p_mfgr,
    (SELECT COUNT(*) FROM RankedSuppliers rs WHERE rs.rank_by_balance <= 3) AS top_3_suppliers_count,
    (SELECT COUNT(*) FROM JoinedOrders jo WHERE jo.total_revenue > (SELECT max_price FROM MaxPartPrice)) AS high_revenue_orders,
    sd.region_name,
    sd.supplier_count,
    CONCAT('Total Revenue: $', ROUND(SUM(jo.total_revenue), 2)) AS revenue_summary
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    SupplierDetails sd ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
JOIN 
    JoinedOrders jo ON p.p_partkey = (SELECT li.l_partkey FROM lineitem li WHERE li.l_orderkey = jo.o_orderkey LIMIT 1)
WHERE 
    p.p_retailprice > (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size < p.p_size)
    OR (SELECT COUNT(*) FROM lineitem li WHERE li.l_partkey = p.p_partkey AND li.l_discount > 0.1) > 0
GROUP BY 
    p.p_name, p.p_mfgr, sd.region_name, sd.supplier_count;
