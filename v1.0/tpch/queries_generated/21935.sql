WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice IS NULL THEN 0 
            ELSE p.p_retailprice 
        END AS adjusted_price
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
OrdersWithLineItems AS (
    SELECT 
        o.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(*) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey
),
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    p.p_name,
    COALESCE(r.suppliers_rank, 'Not Ranked') AS suppliers_rank,
    CASE 
        WHEN h.adjusted_price < 10 THEN 'Cheap'
        WHEN h.adjusted_price BETWEEN 10 AND 100 THEN 'Moderate'
        ELSE 'Expensive'
    END AS price_category,
    o.total_revenue,
    o.item_count,
    IFNULL(sp.total_available, 0) AS total_available_parts
FROM 
    HighValueParts h
LEFT JOIN 
    RankedSuppliers r ON r.rank <= 5
LEFT JOIN 
    OrdersWithLineItems o ON o.o_orderkey IN (
        SELECT 
            l.l_orderkey 
        FROM 
            lineitem l 
        WHERE 
            l.l_partkey = h.p_partkey 
            AND l.l_shipdate > '2022-01-01'
    )
FULL OUTER JOIN 
    SupplierPartDetails sp ON sp.ps_partkey = h.p_partkey
WHERE 
    (r.s_suppkey IS NOT NULL OR sp.supplier_count > 0)
ORDER BY 
    h.adjusted_price DESC NULLS LAST;
