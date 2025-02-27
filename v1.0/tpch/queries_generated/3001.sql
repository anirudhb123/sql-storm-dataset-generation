WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COUNT(ps.ps_partkey) AS total_parts
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationsWithComments AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        COALESCE(ROUND(AVG(s.s_acctbal), 2), 0) AS avg_account_balance
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name, n.n_comment
)
SELECT 
    cu.c_name AS customer_name,
    cu.total_spent,
    cu.order_count,
    ns.n_name AS nation_name,
    ns.avg_account_balance,
    si.s_name AS supplier_name,
    si.total_parts,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus
FROM 
    CustomerSummary cu
LEFT JOIN 
    NationsWithComments ns ON cu.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey)
LEFT JOIN 
    RankedOrders ro ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cu.c_custkey AND o.o_orderstatus = 'O')
LEFT JOIN 
    SupplierInfo si ON si.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cu.c_custkey)))
WHERE 
    cu.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary)
ORDER BY 
    cu.total_spent DESC,
    ro.o_orderdate ASC;
