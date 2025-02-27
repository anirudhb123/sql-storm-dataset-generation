WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        CAST(s.s_name AS VARCHAR(255)) AS full_name
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    UNION ALL
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.n_nationkey,
        CAST(CONCAT(sh.full_name, ' > ', s.s_name) AS VARCHAR(255)) AS full_name
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
),
TopCustomers AS (
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
        SUM(o.o_totalprice) > 5000
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        l.l_linestatus,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(THC.total_spent, 0) AS total_spent_by_customer,
    sh.full_name AS supplier_hierarchy,
    HVO.o_orderkey,
    HVO.o_totalprice
FROM 
    part p
LEFT JOIN 
    HighValueOrders HVO ON HVO.o_orderkey IN (
        SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F'
    )
LEFT JOIN 
    TopCustomers THC ON THC.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = HVO.o_orderkey)
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        WHERE ps.ps_partkey = p.p_partkey 
        LIMIT 1
    )
WHERE 
    p.p_retailprice BETWEEN 100 AND 500
ORDER BY 
    p.p_brand ASC, 
    total_spent_by_customer DESC 
FETCH FIRST 100 ROWS ONLY;
