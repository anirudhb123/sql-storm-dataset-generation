WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = o.o_orderstatus)
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS supplier_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 5
),
FinalReport AS (
    SELECT 
        co.c_name,
        tp.p_name,
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        sd.supplier_comment
    FROM 
        CustomerOrders co
    JOIN 
        lineitem l ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = l.l_orderkey)
    JOIN 
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    JOIN 
        TopParts tp ON l.l_partkey = tp.p_partkey
    LEFT JOIN 
        SupplierDetails sd ON l.l_suppkey = sd.s_suppkey
    WHERE 
        tp.part_rank <= 10
    ORDER BY 
        co.total_spent DESC, ro.o_orderdate
)
SELECT 
    *
FROM 
    FinalReport
WHERE 
    EXISTS (SELECT 1 FROM region r WHERE r.r_name LIKE 'E%' AND r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = FinalReport.c_custkey)))
OR 
    (total_spent IS NULL AND supplier_comment = 'No Comment')
