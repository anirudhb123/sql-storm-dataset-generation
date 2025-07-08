
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
HighValueCust AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 10000
), 
PartWithHighDiscount AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_discount) AS total_discount
    FROM 
        lineitem l
    WHERE 
        l.l_discount > 0.10
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_name,
    COALESCE(ss.total_available_qty, 0) AS available_quantity,
    COALESCE(hc.total_spent, 0) AS high_value_customer_spent,
    COALESCE(phd.total_discount, 0) AS total_discount_on_part,
    p.p_retailprice - COALESCE(phd.total_discount, 0) AS retail_after_discount
FROM 
    part p
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey ORDER BY ps.ps_supplycost ASC FETCH FIRST 1 ROW ONLY)
LEFT JOIN 
    HighValueCust hc ON hc.c_custkey = (SELECT o.o_custkey FROM orders o JOIN lineitem li ON o.o_orderkey = li.l_orderkey WHERE li.l_partkey = p.p_partkey AND o.o_orderstatus = 'O' ORDER BY o.o_totalprice DESC FETCH FIRST 1 ROW ONLY)
LEFT JOIN 
    PartWithHighDiscount phd ON phd.l_partkey = p.p_partkey
WHERE 
    p.p_size >= 10 AND 
    (p.p_comment LIKE '%special%' OR p.p_retailprice < 50.00)
ORDER BY 
    retail_after_discount DESC;
