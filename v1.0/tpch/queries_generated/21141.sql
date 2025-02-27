WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
), PartStats AS (
    SELECT 
        p.p_partkey,
        AVG(ps.ps_supplycost) AS avg_supplycost,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey
), VeryLargeOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
        AND li.l_returnflag = 'N' 
        AND li.l_quantity > 100
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(li.l_extendedprice * (1 - li.l_discount)) > 10000
), SupplierNations AS (
    SELECT 
        s.s_suppkey, 
        n.n_regionkey 
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'A%')
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(r.rank, 0) AS supplier_rank,
    ps.avg_supplycost,
    ps.total_available,
    ps.unique_suppliers,
    v.total_value AS large_order_value,
    CASE 
        WHEN ps.avg_supplycost IS NULL THEN 'No cost available'
        WHEN ps.unique_suppliers = 0 THEN 'No suppliers found'
        ELSE 'Data available'
    END AS data_availability
FROM 
    part p
LEFT JOIN 
    PartStats ps ON p.p_partkey = ps.p_partkey
LEFT JOIN 
    RankedSuppliers r ON r.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey ORDER BY ps_supplycost DESC LIMIT 1)
LEFT JOIN 
    VeryLargeOrders v ON EXISTS (SELECT 1 FROM lineitem li JOIN orders o ON li.l_orderkey = o.o_orderkey WHERE li.l_partkey = p.p_partkey)
WHERE 
    p.p_retailprice IS NOT NULL 
    AND (p.p_size BETWEEN 1 AND 30 OR p.p_comment IS NOT NULL)
ORDER BY 
    p.p_partkey;
