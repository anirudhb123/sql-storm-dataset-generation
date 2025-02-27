WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as supplier_rank,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal ASC) as min_supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue, 
        COUNT(l.l_linenumber) as line_count, 
        o.o_orderstatus,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
SignificantPartSupp AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty - COALESCE((
            SELECT SUM(l.l_quantity) 
            FROM lineitem l 
            WHERE l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
            GROUP BY l.l_partkey, l.l_suppkey
        ), 0) AS availability
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
),
CombinedData AS (
    SELECT 
        COALESCE(r.r_name, 'UNKNOWN') AS region_name,
        p.p_name,
        p.p_retailprice,
        COALESCE(hl.total_revenue, 0) AS high_value_revenue,
        COALESCE(rs.supplier_rank, 0) AS supplier_rank
    FROM 
        part p
    LEFT JOIN 
        (SELECT DISTINCT p_partkey FROM SignificantPartSupp sps WHERE sps.availability > 50) AS significant_parts 
        ON p.p_partkey = significant_parts.p_partkey
    LEFT JOIN 
        RankedSuppliers rs ON rs.s_suppkey = (
            SELECT ps_suppkey 
            FROM partsupp 
            WHERE ps_partkey = p.p_partkey 
            ORDER BY ps_supplycost DESC 
            LIMIT 1
        )
    LEFT JOIN 
        HighValueOrders hl ON hl.o_orderkey = (
            SELECT o_orderkey 
            FROM orders 
            WHERE o_orderstatus = 'F' 
            ORDER BY o_totalprice DESC 
            LIMIT 1
        )
    LEFT JOIN 
        nation n ON n.n_nationkey = rs.s_nationkey
    LEFT JOIN 
        region r ON r.r_regionkey = n.n_regionkey
)
SELECT 
    region_name, 
    p_name, 
    p_retailprice, 
    high_value_revenue, 
    supplier_rank 
FROM 
    CombinedData
WHERE 
    (high_value_revenue > 10000 OR supplier_rank < 5)
    AND p_retailprice IS NOT NULL
ORDER BY 
    region_name, high_value_revenue DESC, p_retailprice ASC;
