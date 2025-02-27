WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1996-01-01'
        AND o.o_totalprice IS NOT NULL
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No comments available') AS supplier_comment,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_availqty) > 1000
),
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    ps.total_supply_cost,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    STRING_AGG(DISTINCT sd.supplier_comment, '; ') AS supplier_comments,
    SUM(CASE WHEN ro.order_rank <= 10 THEN ro.o_totalprice ELSE 0 END) AS top_orders_value,
    CASE 
        WHEN COUNT(DISTINCT co.cust_order_count) = 0 THEN 'No Orders'
        ELSE 'Orders Exist'
    END AS order_status
FROM 
    part p
LEFT JOIN 
    PartSupplierStats ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    CustomerOrderCounts co ON co.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_comment NOT LIKE '%test%')
LEFT JOIN 
    SupplierDetails sd ON sd.s_suppkey IN (SELECT DISTINCT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE 
    p.p_size BETWEEN 1 AND 25
    AND (p.p_retailprice IS NOT NULL OR ps.total_supply_cost IS NULL)
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, ps.total_supply_cost
HAVING 
    SUM(ps.total_supply_cost) > COALESCE(NULLIF(MAX(ro.o_totalprice), 0), 1)
ORDER BY 
    p.p_partkey;
