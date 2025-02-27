WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_size, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_size ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL 
        AND p.p_size BETWEEN 1 AND 100
), 
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CASE 
            WHEN ps.ps_supplycost IS NULL THEN 'No Cost' 
            ELSE CAST(ps.ps_supplycost AS VARCHAR)
        END AS supply_cost_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
CustomerOrders AS (
    SELECT 
        o.o_orderkey, 
        c.c_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(*) AS total_line_items,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_custkey
), 
TopRegions AS (
    SELECT 
        n.n_regionkey, 
        n.n_name, 
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS fulfilled_orders
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_regionkey, n.n_name
    HAVING 
        fulfilled_orders > 0
), 
FinalAggregation AS (
    SELECT 
        r.r_name, 
        COALESCE(SUM(sp.ps_availqty), 0) AS total_avail_qty,
        COUNT(DISTINCT co.o_orderkey) AS total_orders,
        COUNT(DISTINCT rp.p_partkey) AS total_ranked_parts
    FROM 
        TopRegions r
    LEFT JOIN 
        SupplierPartDetails sp ON r.n_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = r.r_name)
    LEFT JOIN 
        CustomerOrders co ON co.total_order_value IS NOT NULL
    LEFT JOIN 
        RankedParts rp ON rp.rn <= 10
    GROUP BY 
        r.r_name
)
SELECT 
    f.r_name, 
    f.total_avail_qty,
    f.total_orders, 
    f.total_ranked_parts, 
    CASE 
        WHEN f.total_orders = 0 THEN 'No Orders' 
        ELSE CAST(f.total_avail_qty / f.total_orders AS VARCHAR)
    END AS avg_avail_per_order
FROM 
    FinalAggregation f
WHERE 
    f.total_avail_qty IS NOT NULL
ORDER BY 
    f.total_avail_qty DESC NULLS LAST;
