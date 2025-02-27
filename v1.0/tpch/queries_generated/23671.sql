WITH RankedSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost,
        COUNT(*) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COALESCE(SUM(o.o_totalprice), 0) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
FilteredPart AS (
    SELECT 
        p.p_partkey,
        p.p_retailprice,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNKNOWN'
            ELSE p.p_size::TEXT
        END AS part_size_string
    FROM 
        part p
    WHERE 
        EXISTS (
            SELECT 1
            FROM partsupp ps
            WHERE ps.ps_partkey = p.p_partkey
            AND ps.ps_availqty > 0
        ) 
        AND p.p_retailprice IS NOT NULL
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_discount,
        ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS detail_order
    FROM 
        lineitem l
    WHERE 
        l.l_returnflag = 'N'
)
SELECT 
    f.p_partkey,
    f.part_size_string,
    f.p_retailprice,
    COALESCE(cs.total_spent, 0) AS total_spent_by_customer,
    COALESCE(s.rn, 10) AS ranked_supplier_status,
    ods.l_discount,
    ods.detail_order
FROM 
    FilteredPart f
LEFT JOIN 
    CustomerOrderSummary cs ON cs.total_spent = (
        SELECT MAX(total_spent) 
        FROM CustomerOrderSummary)
LEFT JOIN 
    RankedSupplier s ON s.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = f.p_partkey 
        ORDER BY ps.ps_availqty DESC 
        LIMIT 1)
LEFT JOIN 
    OrderDetails ods ON ods.l_partkey = f.p_partkey
WHERE 
    f.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2 
        WHERE p2.p_size IS NOT NULL)
ORDER BY 
    f.p_partkey, 
    total_spent_by_customer DESC, 
    detail_order;
