WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS status_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS customer_total
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
    GROUP BY 
        c.c_custkey
),
CrossJoinedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(s.total_supplycost, 0) AS total_supplycost,
        COALESCE(h.customer_total, 0) AS customer_total
    FROM 
        part p
    LEFT JOIN 
        SupplierSummary s ON p.p_partkey = s.ps_partkey
    LEFT JOIN 
        HighValueCustomers h ON h.customer_total > p.p_retailprice
)
SELECT 
    cd.p_partkey, 
    cd.p_name, 
    cd.p_retailprice,
    ROUND(cd.total_supplycost / NULLIF(cd.customer_total, 0), 2) AS cost_to_customer_ratio,
    o.o_orderstatus
FROM 
    CrossJoinedData cd
LEFT JOIN 
    RankedOrders o ON o.o_orderkey = (SELECT MAX(o2.o_orderkey) 
                                          FROM RankedOrders o2 
                                          WHERE o2.status_rank = 1 
                                          AND cd.p_partkey = ANY (SELECT DISTINCT l.l_partkey 
                                                                   FROM lineitem l 
                                                                   WHERE l.l_orderkey = o.o_orderkey 
                                                                   AND l.l_returnflag = 'N'))
WHERE 
    cd.total_supplycost > 0
ORDER BY 
    cd.cost_to_customer_ratio DESC, 
    cd.p_retailprice ASC;
