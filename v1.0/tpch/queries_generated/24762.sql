WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rnk
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('F', 'N')
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
    HAVING 
        SUM(ps.ps_availqty) > 0
), CustomerPurchases AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        c.c_custkey
), NationalSuppliers AS (
    SELECT 
        s.s_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS num_suppliers 
    FROM 
        supplier s 
    GROUP BY 
        s.s_nationkey 
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 2
), TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(ps.total_avail_qty, 0) AS total_avail_qty,
        RANK() OVER (ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    LEFT JOIN 
        SupplierParts ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        LENGTH(p.p_name) >= 5 AND p.p_retailprice IS NOT NULL
)
SELECT 
    c.c_custkey,
    c.c_name,
    COALESCE(tp.p_name, 'No Part Available') AS part_name,
    tp.p_retailprice,
    coalesce(c.total_spent, 0) AS total_spent,
    n.n_name AS nation_name,
    CASE 
        WHEN c.c_acctbal IS NULL THEN 'Unknown Balance'
        ELSE CASE 
            WHEN c.c_acctbal < 1000 THEN 'Low Balance'
            WHEN c.c_acctbal BETWEEN 1000 AND 5000 THEN 'Medium Balance'
            ELSE 'High Balance'
        END
    END AS balance_category
FROM 
    CustomerPurchases c
LEFT JOIN 
    TopParts tp ON tp.price_rank <= 10
JOIN 
    supplier s ON s.s_suppkey = tp.total_avail_qty
JOIN 
    NationalSuppliers n ON s.s_nationkey = n.s_nationkey
WHERE 
    tp.total_avail_qty IS NOT NULL OR tp.total_avail_qty IS NULL
ORDER BY 
    total_spent DESC, part_name ASC;
