
WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM 
        customer c
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 50000
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_container,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_name AS supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        HighValueSuppliers s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    rc.c_name,
    SUM(pd.ps_availqty) AS total_avail_qty,
    AVG(pd.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT pd.supplier_name) AS distinct_suppliers,
    STRING_AGG(CONCAT(pd.p_name, ' (', pd.p_container, ')'), ', ') AS part_info
FROM 
    RankedCustomers rc
JOIN 
    orders o ON rc.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    PartDetails pd ON l.l_partkey = pd.p_partkey
WHERE 
    rc.rank_acctbal <= 10
GROUP BY 
    rc.c_name
ORDER BY 
    distinct_suppliers DESC, rc.c_name;
