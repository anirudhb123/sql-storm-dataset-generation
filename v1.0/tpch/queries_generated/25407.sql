WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CONCAT(s.s_name, ' - ', s.s_address) AS Supplier_Details
    FROM supplier s
    WHERE s.s_acctbal > 1000
), 
PartInfo AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        REPLACE(LOWER(p.p_comment), ' ', '-') AS Formatted_Comment
    FROM part p
    WHERE p.p_retailprice < 50
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS Line_Count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey
), 
CombinedInfo AS (
    SELECT 
        si.Supplier_Details, 
        pi.p_name, 
        ci.c_name, 
        ci.Line_Count
    FROM SupplierInfo si
    JOIN PartInfo pi ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pi.p_partkey LIMIT 1)
    JOIN CustomerOrders ci ON ci.Line_Count > 5
)
SELECT 
    ci.Supplier_Details,
    ci.p_name, 
    ci.c_name, 
    ci.Line_Count, 
    LEFT(ci.Supplier_Details, 15) AS Short_Supplier_Name
FROM CombinedInfo ci
ORDER BY ci.Line_Count DESC, ci.Supplier_Details ASC
LIMIT 10;
