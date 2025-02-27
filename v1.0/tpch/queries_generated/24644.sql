WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        n.n_regionkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartSupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 0
            ELSE ps.ps_availqty * ps.ps_supplycost 
        END AS total_supply_value
    FROM 
        partsupp ps
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CTE_MAX.largest_discount
    FROM 
        orders o
    JOIN (
        SELECT 
            l.l_orderkey,
            MAX(l.l_discount) AS largest_discount
        FROM 
            lineitem l
        GROUP BY 
            l.l_orderkey
    ) CTE_MAX ON o.o_orderkey = CTE_MAX.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_retailprice,
    COALESCE(MAX(r.min_supply_cost), 0) AS min_supply_cost,
    COALESCE(MAX(rs.s_name), 'No Supplier') AS supplier_name,
    COALESCE(SUM(ro.o_totalprice), 0) AS total_orders_value,
    COUNT(DISTINCT rs.s_suppkey) AS supplier_count
FROM 
    part p
LEFT JOIN 
    PartSupplierDetails r ON p.p_partkey = r.ps_partkey
LEFT JOIN 
    RankedSuppliers rs ON r.ps_suppkey = rs.s_suppkey AND rs.supplier_rank <= 3
LEFT JOIN 
    RecentOrders ro ON p.p_partkey = SOME(SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey)
WHERE 
    (p.p_retailprice > 100 OR p.p_container IS NULL)
    AND NOT EXISTS (
        SELECT *
        FROM region rg
        WHERE rg.r_name = 'APAC' AND rg.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = 'China')
    )
GROUP BY 
    p.p_partkey, p.p_name, p.p_retailprice
HAVING 
    SUM(r.ps_supplycost) IS DISTINCT FROM NULL
ORDER BY 
    total_orders_value DESC, p.p_name ASC;
