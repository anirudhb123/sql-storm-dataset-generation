WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
),
FilteredLineItems AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        COUNT(*) AS line_count
    FROM 
        lineitem li
    WHERE 
        li.l_returnflag = 'N' AND 
        li.l_shipdate > (CURRENT_DATE - INTERVAL '1 year')
    GROUP BY 
        li.l_orderkey
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        MAX(s.s_acctbal) AS max_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
NationRegion AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        nation n 
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    d.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(li.total_sales) AS total_sales,
    AVG(sd.max_acctbal) AS avg_supplier_acctbal
FROM 
    RankedOrders o
JOIN 
    FilteredLineItems li ON o.o_orderkey = li.l_orderkey
JOIN 
    SupplierDetails sd ON sd.part_count > 5
JOIN 
    NationRegion d ON d.n_nationkey = (SELECT DISTINCT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN 
    region r ON d.r_name = r.r_name
WHERE 
    o.o_orderstatus IN ('F', 'P')
AND 
    o.o_orderdate IS NOT NULL
GROUP BY 
    d.n_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_sales DESC, nation_name ASC;
