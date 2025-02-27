WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
FilteredNation AS (
    SELECT 
        n.n_nationkey,
        n.n_name
    FROM 
        nation n
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%land%')
)

SELECT 
    p.p_name,
    p.p_brand,
    si.s_name,
    si.total_avail_qty,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN li.l_discount > 0 THEN li.l_extendedprice * (1 - li.l_discount) ELSE 0 END) AS total_discounted_revenue,
    AVG(o.o_totalprice) OVER (PARTITION BY si.s_nationkey) AS avg_order_price_per_supplier,
    CASE 
        WHEN COUNT(o.o_orderkey) = 0 THEN 'No Orders'
        ELSE (SELECT n.n_name FROM FilteredNation n WHERE n.n_nationkey = si.s_nationkey LIMIT 1)
    END AS nation_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier si ON ps.ps_suppkey = si.s_suppkey
LEFT JOIN 
    lineitem li ON li.l_suppkey = si.s_suppkey
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = li.l_orderkey
GROUP BY 
    p.p_name, p.p_brand, si.s_name, si.total_avail_qty, si.s_nationkey
HAVING 
    SUM(li.l_quantity) > 0 
    AND MAX(si.max_acctbal) IS NOT NULL
ORDER BY 
    total_discounted_revenue DESC NULLS LAST;
