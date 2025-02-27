
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_status
    FROM 
        orders o 
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' 
        AND o.o_orderdate <= DATE '1997-12-31'
),
SupplierParts AS (
    SELECT 
        s.s_name, 
        p.p_name, 
        ps.ps_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_container LIKE '%BOX%'
),
HighSpendCustomers AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL 
        AND c.c_acctbal > 1000
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 5000
),
NationSuppliers AS (
    SELECT 
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_name
    HAVING 
        COUNT(s.s_suppkey) > 5
)
SELECT 
    r.r_name,
    ns.supplier_count,
    SUM(CASE 
            WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice * (1 - lo.l_discount)
            ELSE 0 
        END) AS total_returned,
    AVG(ho.total_spent) AS avg_spent
FROM 
    region r
LEFT JOIN 
    NationSuppliers ns ON r.r_regionkey = ns.supplier_count
LEFT JOIN 
    RankedOrders ro ON ro.rank_status <= 10
LEFT JOIN 
    HighSpendCustomers ho ON ho.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = ns.supplier_count
        LIMIT 1
    )
LEFT JOIN 
    lineitem lo ON lo.l_orderkey = ro.o_orderkey
WHERE 
    ns.supplier_count IS NOT NULL 
    AND r.r_comment IS NOT NULL
GROUP BY 
    r.r_name, ns.supplier_count
ORDER BY 
    total_returned DESC, avg_spent ASC
LIMIT 50;
