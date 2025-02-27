WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        s.s_comment,
        CONCAT(s.s_name, ' - ', s.s_comment) AS supplier_details,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s1.s_acctbal) FROM supplier s1 
            WHERE s1.s_nationkey = s.s_nationkey
        )
), 
NationDetails AS (
    SELECT 
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        SupplierInfo s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
), 
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supply_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(p.p_retailprice) AS max_retail_price
    FROM 
        part p 
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    n.n_name,
    p.p_name,
    p.supply_count,
    p.avg_supply_cost,
    s.supplier_details,
    s.comment_length
FROM 
    NationDetails n
JOIN 
    PartStats p ON n.supplier_count > p.supply_count
JOIN 
    SupplierInfo s ON s.s_nationkey = n.n_nationkey
ORDER BY 
    n.n_name, p.avg_supply_cost DESC;
