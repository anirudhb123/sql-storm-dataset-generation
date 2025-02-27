WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey = n.n_nationkey)
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        ps.ps_availqty,
        CASE 
            WHEN ps.ps_availqty IS NULL THEN 'Out of Stock' 
            ELSE 'In Stock' 
        END AS stock_status
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND 
        l.l_shipmode IN ('AIR', 'SHIP')
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pd.p_name,
    rs.s_name,
    rs.s_acctbal,
    os.total_sales,
    os.avg_quantity,
    CASE 
        WHEN os.avg_quantity IS NULL THEN 'No Orders' 
        ELSE CASE 
            WHEN os.avg_quantity > 100 THEN 'Bulk Orders' 
            ELSE 'Regular Orders' 
        END 
    END AS order_type,
    r.r_name
FROM 
    PartDetails pd
LEFT JOIN 
    RankedSupplier rs ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = rs.s_suppkey)
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n JOIN supplier s ON n.n_nationkey = s.s_nationkey WHERE s.s_suppkey = rs.s_suppkey)
LEFT JOIN 
    OrderSummary os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pd.p_partkey)
WHERE 
    pd.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) * 1.1
ORDER BY 
    pd.p_retailprice DESC, 
    rs.s_acctbal ASC
LIMIT 10;
