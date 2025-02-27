WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_type, 
        p.p_brand, 
        p.p_container, 
        p.p_size, 
        p.p_retailprice, 
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS TypeRank
    FROM part p
    WHERE p.p_size > 10 AND p.p_retailprice < 100.00
), 
SelectedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS TotalOrders, 
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT 
    rp.p_name, 
    rp.p_container, 
    rp.p_retailprice, 
    ss.s_name AS supplier_name, 
    css.c_name AS customer_name, 
    css.TotalOrders, 
    css.TotalSpent
FROM RankedParts rp
JOIN SelectedSuppliers ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
JOIN CustomerOrderSummary css ON css.TotalOrders > 10
ORDER BY rp.p_retailprice DESC, css.TotalSpent DESC;
