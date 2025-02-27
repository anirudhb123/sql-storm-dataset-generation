WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY p.p_retailprice) OVER () AS price_threshold
    FROM 
        part p
    WHERE 
        p.p_retailprice > 10.50
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_discount * l.l_extendedprice) AS total_discount,
        AVG(l.l_extendedprice) AS avg_price,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        os.total_discount,
        os.avg_price,
        os.unique_suppliers
    FROM 
        orders o
    JOIN 
        OrderStats os ON o.o_orderkey = os.o_orderkey
    WHERE 
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 
        AND os.total_discount IS NOT NULL
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        partsupp ps
    WHERE 
        ps.ps_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp) 
        OR ps.ps_availqty IS NULL
),
FinalReport AS (
    SELECT 
        hvo.o_orderkey,
        COUNT(DISTINCT fs.ps_partkey) AS part_count,
        SUM(fs.ps_supplycost) AS total_supply_cost,
        s.s_name
    FROM 
        HighValueOrders hvo
    LEFT JOIN 
        SupplierParts fs ON hvo.o_orderkey = fs.ps_partkey 
    LEFT JOIN 
        RankedSuppliers s ON fs.ps_suppkey = s.s_suppkey AND s.supplier_rank < 5
    GROUP BY 
        hvo.o_orderkey, s.s_name
    HAVING 
        AVG(fs.ps_supplycost) <= hvo.avg_price OR s.s_name IS NULL
)
SELECT 
    f.o_orderkey,
    f.part_count,
    f.total_supply_cost,
    COALESCE(f.s_name, 'Unavailable') AS supplier_name
FROM 
    FinalReport f
WHERE 
    f.total_supply_cost > 100.00 
ORDER BY 
    f.o_orderkey ASC, 
    f.part_count DESC;
