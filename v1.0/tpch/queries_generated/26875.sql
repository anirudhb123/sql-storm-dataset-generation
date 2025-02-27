WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS top_rank
    FROM 
        supplier s
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(*) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(od.total_revenue) AS total_spent,
        COUNT(od.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
FinalReport AS (
    SELECT 
        rp.p_name,
        rp.p_brand,
        ts.s_name AS supplier_name,
        ts.s_acctbal AS supplier_account_balance,
        cos.c_name AS customer_name,
        cos.total_spent,
        cos.order_count
    FROM 
        RankedParts rp
    JOIN 
        TopSuppliers ts ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = rp.p_retailprice LIMIT 1)
    JOIN 
        CustomerOrderSummary cos ON ts.s_nationkey = cos.c_custkey
    WHERE 
        rp.rank <= 5 AND ts.top_rank <= 10
)
SELECT 
    * 
FROM 
    FinalReport
ORDER BY 
    total_spent DESC;
