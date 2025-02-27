WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1996-12-31'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Account balance unavailable'
            WHEN s.s_acctbal < 0 THEN 'Negative balance'
            ELSE 'Active Supplier'
        END AS supplier_status
    FROM 
        supplier s
    WHERE 
        s.s_comment LIKE '%good%'
),
PartSuppDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    pr.p_partkey,
    pr.p_name,
    pr.p_retailprice,
    COALESCE(sd.supplier_status, 'No Status Available') AS supplier_status,
    cr.region_name,
    ROW_NUMBER() OVER (PARTITION BY cr.region_name ORDER BY pr.p_retailprice DESC) AS retail_rank
FROM 
    part pr
LEFT JOIN 
    PartSuppDetails psd ON pr.p_partkey = psd.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON psd.ps_suppkey = sd.s_suppkey
JOIN 
    CustomerRegions cr ON sd.s_suppkey IN (SELECT s_suppkey FROM partsupp WHERE ps_availqty > 0)
WHERE 
    pr.p_retailprice BETWEEN (SELECT AVG(p_retailprice) FROM part) AND (SELECT AVG(p_retailprice) FROM part WHERE p_size > 5)
ORDER BY 
    cr.region_name, retail_rank
OPTION (MAXRECURSION 0);
