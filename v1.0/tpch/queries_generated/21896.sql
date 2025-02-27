WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > 100000 THEN 'High'
            WHEN s.s_acctbal BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS acctbal_category
    FROM 
        supplier s
    WHERE 
        s.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 10)
),
OrdersWithDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_extended_price,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice
),
RegionInfo AS (
    SELECT 
        n.n_name as nation_name,
        r.r_name as region_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name, r.r_name
),
OuterJoinSample AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COALESCE(s.s_name, 'No Supplier') AS supplier_name,
        rp.price_rank,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supplier_count
    FROM 
        RankedParts rp
    LEFT JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        rp.price_rank <= 5
)
SELECT 
    owd.o_orderkey,
    owd.o_orderdate,
    owd.total_extended_price,
    ri.region_name,
    ri.nation_name,
    owd.line_item_count,
    u.s_name,
    (SELECT AVG(c.c_acctbal) 
     FROM customer c 
     WHERE c.c_custkey IN 
       (SELECT o.o_custkey 
        FROM orders o 
        WHERE o.o_orderkey = owd.o_orderkey)) AS average_customer_bal
FROM 
    OrdersWithDetails owd
JOIN 
    RegionInfo ri ON ri.supplier_count > 5
LEFT JOIN 
    OuterJoinSample u ON u.p_partkey IN (SELECT DISTINCT l.l_partkey FROM lineitem l WHERE l.l_orderkey = owd.o_orderkey)
WHERE 
    owd.total_extended_price > (SELECT AVG(total_extended_price) FROM OrdersWithDetails)
ORDER BY 
    owd.o_orderdate DESC, 
    owd.total_extended_price ASC
LIMIT 10;
