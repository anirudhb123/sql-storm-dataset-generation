WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
), 
OrderStatistics AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returns,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.lineitem_count,
        o.total_revenue,
        o.returns,
        o.avg_quantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.total_revenue DESC NULLS LAST) AS customer_order_rank
    FROM 
        customer c
    JOIN 
        OrderStatistics o ON c.c_custkey = o.o_custkey
), 
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        COALESCE(NULLIF(p.p_retailprice, ps.ps_supplycost), 0) AS adjusted_price,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_supplycost
)
SELECT 
    c.c_name,
    c.c_custkey,
    os.lineitem_count,
    ps.p_name,
    ps.adjusted_price,
    (SELECT SUM(oss.total_revenue) 
     FROM CustomerOrderSummary oss 
     WHERE oss.c_custkey = c.c_custkey 
     AND oss.customer_order_rank <= 5) AS top_five_revenue,
    CASE 
        WHEN r.rank IS NOT NULL THEN 'High Balancer' 
        ELSE 'Regular' 
    END AS supplier_type
FROM 
    CustomerOrderSummary os
JOIN 
    part p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps ORDER BY PS.ps_supplycost DESC LIMIT 1)
LEFT JOIN 
    RankedSuppliers r ON r.s_suppkey = (SELECT ps.ps_suppkey 
                                          FROM partsupp ps 
                                          WHERE ps.ps_partkey = p.p_partkey 
                                          ORDER BY ps.ps_availqty DESC 
                                          FETCH FIRST 1 ROW ONLY)
JOIN 
    PartSupplierDetails ps ON ps.p_partkey = p.p_partkey
WHERE 
    os.total_revenue > (SELECT AVG(total_revenue) FROM OrderStatistics) 
    OR os.avg_quantity IS NULL
ORDER BY 
    adjusted_price DESC, lineitem_count DESC
FETCH FIRST 100 ROWS ONLY;
