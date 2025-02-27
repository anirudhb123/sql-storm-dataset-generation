WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rnk
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%rubber%'
), 
CustomerOrders AS (
    SELECT 
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        DATEDIFF(CURDATE(), o.o_orderdate) AS days_since_order
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
), 
SupplierStatistics AS (
    SELECT 
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        AVG(s.s_acctbal) AS avg_acct_bal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
)
SELECT 
    rp.p_name AS part_name,
    rp.p_brand AS part_brand,
    co.c_name AS customer_name,
    co.o_orderkey AS order_key,
    co.days_since_order,
    ss.s_name AS supplier_name,
    ss.total_parts,
    ss.total_value,
    ss.avg_acct_bal
FROM 
    RankedParts rp
JOIN 
    CustomerOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = rp.p_partkey
    )
JOIN 
    SupplierStatistics ss ON ss.total_parts > 0
WHERE 
    rp.rnk <= 5
ORDER BY 
    rp.p_brand, co.days_since_order DESC, ss.total_value DESC;
