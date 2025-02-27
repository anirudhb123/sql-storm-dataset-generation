WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(DISTINCT o.o_orderkey) > 5
), 
PartSupplierAvg AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
), 
ComplexSubquery AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT CASE WHEN ps.ps_availqty IS NULL THEN 1 END) AS null_avail_qty_count,
        SUM(CASE WHEN p.p_size > 10 THEN ps.ps_supplycost ELSE 0 END) AS high_size_supplycost
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        n.n_name
), 
InteractionSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice) > 1000
)

SELECT 
    cs.c_custkey,
    cs.total_orders,
    cs.total_spent,
    COALESCE(rs.s_name, 'No Supplier') as supplier_name,
    psa.avg_supplycost,
    ci.n_name,
    ci.null_avail_qty_count,
    ci.high_size_supplycost,
    isum.lineitem_count,
    isum.total_lineitem_value,
    CASE 
        WHEN SUM(isum.total_lineitem_value) > 5000 THEN 'High Value'
        ELSE 'Low Value'
    END AS order_value_category
FROM 
    CustomerOrderSummary cs
FULL OUTER JOIN 
RankedSuppliers rs ON cs.total_orders = rs.supplier_rank
FULL OUTER JOIN 
PartSupplierAvg psa ON cs.total_orders = psa.supplier_count
FULL OUTER JOIN 
ComplexSubquery ci ON cs.c_custkey = ci.null_avail_qty_count
FULL OUTER JOIN 
InteractionSummary isum ON cs.total_orders = isum.lineitem_count
WHERE 
    (cs.total_spent IS NOT NULL OR rs.s_name IS NOT NULL)
    AND (psa.avg_supplycost > 100 OR ci.high_size_supplycost IS NOT NULL)
ORDER BY 
    cs.total_spent DESC NULLS LAST;
