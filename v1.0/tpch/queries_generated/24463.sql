WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        CEIL(ps.ps_supplycost * 1.2) AS inflated_cost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
),
PartSupplierRank AS (
    SELECT 
        pp.p_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(sp.inflated_cost) AS avg_supplycost
    FROM 
        part pp
    LEFT JOIN 
        SupplierPartInfo sp ON pp.p_partkey = sp.ps_partkey
    GROUP BY 
        pp.p_partkey
),
FinalAggregation AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        SUM(hv.total_value) AS total_high_value_orders,
        COUNT(DISTINCT ps.p_partkey) FILTER (WHERE ps.supplier_count > 1) AS multi_supplier_parts
    FROM 
        HighValueOrders hv
    JOIN 
        customer c ON c.c_custkey = hv.o_orderkey
    JOIN 
        nation ns ON c.c_nationkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    LEFT JOIN 
        PartSupplierRank ps ON ps.p_partkey = hv.o_orderkey
    GROUP BY 
        r.r_name, ns.n_name
)
SELECT 
    region_name,
    nation_name,
    total_high_value_orders,
    multi_supplier_parts
FROM 
    FinalAggregation
WHERE 
    total_high_value_orders IS NOT NULL
ORDER BY 
    total_high_value_orders DESC,
    nation_name ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
