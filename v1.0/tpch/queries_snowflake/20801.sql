
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
),
SupplierPartInfo AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_availqty, 
        s.s_name,
        s.s_acctbal, 
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS availability_rank
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty IS NOT NULL AND 
        s.s_acctbal >= (SELECT AVG(s_acctbal) FROM supplier WHERE s_comment IS NOT NULL)
),
TotalLineItemProfit AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_profit,
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1997-01-01'
    GROUP BY 
        l.l_orderkey
),
PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    LEFT JOIN  
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS final_order_total,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.total_profit) AS median_profit,
    LISTAGG(DISTINCT CONCAT(p.p_name, ' - ', sp.s_name), '; ') WITHIN GROUP (ORDER BY p.p_name) AS part_supplier_list
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    TotalLineItemProfit t ON o.o_orderkey = t.l_orderkey
LEFT JOIN 
    SupplierPartInfo sp ON sp.ps_partkey IN (SELECT p.p_partkey FROM part p)
LEFT JOIN 
    PartSupplierDetails p ON p.p_partkey = sp.ps_partkey
WHERE 
    r.r_name LIKE 'S%' 
    AND o.o_orderdate > '1996-01-01'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    customer_count DESC, final_order_total DESC;
