WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_available_qty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
), SupplierRanking AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_totalprice,
    li.l_quantity,
    li.l_extendedprice,
    COALESCE(NULLIF(li.l_discount, 0), 0.1) AS effective_discount,
    ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY li.l_linenumber) AS line_item_order,
    CASE 
        WHEN li.l_returnflag = 'R' THEN 'Returned' 
        ELSE 'Not Returned' 
    END AS return_status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
JOIN 
    orders o ON li.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    RecursiveCTE rc ON p.p_partkey = rc.p_partkey
WHERE 
    (o.o_orderstatus = 'F' AND o.o_totalprice > 1000) 
    OR (li.l_discount > 0.05 AND li.l_discount < 0.15)
    AND (rc.total_available_qty IS NOT NULL OR rc.rn = 1)
ORDER BY 
    region_name, nation_name, customer_name, o.o_orderkey;
