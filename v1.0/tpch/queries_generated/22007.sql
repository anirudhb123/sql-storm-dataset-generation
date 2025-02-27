WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_container = 'SMALL')
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COALESCE((SELECT SUM(ps.ps_supplycost * ps.ps_availqty) FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey), 0) AS total_supply_cost
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0 AND
        s.s_name LIKE '%Corp%'
),
QualifiedOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATEADD(YEAR, -1, CURRENT_DATE)
    GROUP BY 
        o.o_orderkey
),
FilteredSuppliers AS (
    SELECT 
        si.s_suppkey, 
        si.s_name, 
        si.total_supply_cost
    FROM 
        SupplierInfo si
    WHERE 
        si.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierInfo)
)
SELECT 
    rp.p_name, 
    rp.p_retailprice, 
    fs.s_name, 
    fs.total_supply_cost,
    qo.total_lineitem_value,
    CASE 
        WHEN qo.total_lineitem_value IS NULL THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status
FROM 
    RankedParts rp
LEFT JOIN 
    FilteredSuppliers fs ON fs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
LEFT JOIN 
    QualifiedOrders qo ON qo.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'CANADA')))
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC NULLS LAST;
