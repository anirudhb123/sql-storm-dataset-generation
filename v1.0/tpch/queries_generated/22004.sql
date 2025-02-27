WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
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
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
), 
SupplierProducts AS (
    SELECT 
        DISTINCT p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        r.r_name AS supplier_region
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ps.ps_availqty IS NOT NULL AND 
        p.p_retailprice > 0
)
SELECT 
    COALESCE(hvo.o_orderkey, 0) AS order_key,
    COALESCE(rs.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(sp.p_name, 'No Product') AS product_name,
    COUNT(DISTINCT IF(rs.rank <= 3, rs.s_suppkey, NULL)) AS top_suppliers,
    SUM(sp.ps_supplycost) AS total_supply_cost,
    hvo.total_revenue AS revenue_generated
FROM 
    HighValueOrders hvo
FULL OUTER JOIN RankedSuppliers rs ON hvo.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_custkey = hvo.o_custkey AND c.c_acctbal IS NOT NULL LIMIT 1)
LEFT JOIN SupplierProducts sp ON sp.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = hvo.o_orderkey LIMIT 1)
GROUP BY 
    hvo.o_orderkey, rs.s_name, sp.p_name, hvo.total_revenue
ORDER BY 
    total_supply_cost DESC, revenue_generated DESC
LIMIT 100;
