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
        o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
),
SupplierAggregates AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        n.n_name,
        r.r_name
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    o.o_orderkey,
    oo.o_orderdate,
    oo.o_totalprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(sa.total_cost, 0) AS total_supply_cost,
    rn.n_name AS nation_name,
    rn.r_name AS region_name,
    CASE 
        WHEN oo.o_orderstatus = 'F' THEN 'Finished' 
        ELSE 'Pending' 
    END AS status_description
FROM 
    RankedOrders oo
LEFT JOIN 
    lineitem l ON oo.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierAggregates sa ON l.l_partkey = sa.ps_partkey
LEFT JOIN 
    TopSuppliers s ON sa.supplier_count > 1 AND s.supplier_rank <= 5
JOIN 
    RegionNation rn ON rn.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = oo.o_orderkey)
WHERE 
    oo.order_rank <= 10
ORDER BY 
    oo.o_orderdate DESC, 
    total_supply_cost DESC;
