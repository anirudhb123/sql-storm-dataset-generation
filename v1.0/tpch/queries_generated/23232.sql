WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND p.p_size IN (SELECT DISTINCT ps.ps_supplycost FROM partsupp ps WHERE ps.ps_availqty > 0)
), SelectedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(DISTINCT ps.ps_partkey) > 5
), CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled_price
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT 
    rp.p_name AS high_value_part,
    ss.s_name AS supplier_name,
    c.c_name AS customer_name,
    coalesce(ho.total_value, 0) AS high_value_order_total,
    RANK() OVER (PARTITION BY rp.p_partkey ORDER BY coalesce(ho.total_value, 0) DESC) AS value_rank
FROM 
    RankedParts rp
LEFT JOIN 
    SelectedSuppliers ss ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ss.s_suppkey)
LEFT JOIN 
    CustomerOrderCounts c ON c.order_count > 0
LEFT JOIN 
    HighValueOrders ho ON c.c_custkey = ho.o_custkey
WHERE 
    rp.rn <= 10
ORDER BY 
    rp.p_name, supplier_name, customer_name;
