WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' 
        AND o.o_totalprice IS NOT NULL
), 
SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        ps.ps_supplycost, 
        p.p_name, 
        p.p_retailprice,
        NULLIF(p.p_retailprice, 0) AS adjusted_price
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 0
), 
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
), 
MaxPrice AS (
    SELECT 
        MAX(ps_supplycost) AS max_supplycost
    FROM 
        SupplierPartDetails
    WHERE 
        adjusted_price IS NOT NULL
)

SELECT 
    r.cust_info,
    COALESCE(SUM(s.ps_supplycost), 0) AS total_supplier_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    p.p_name,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY COUNT(DISTINCT o.o_orderkey) DESC) AS customer_order_rank
FROM 
    CustomerSummary cs
LEFT JOIN 
    RankedOrders ro ON cs.c_custkey = ro.o_custkey
JOIN 
    supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM SupplierPartDetails ps WHERE ps.ps_supplycost < (SELECT max_supplycost FROM MaxPrice))
JOIN 
    part p ON p.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey LIMIT 1)
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
GROUP BY 
    r.cust_info, p.p_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 1 AND total_supplier_cost > (
        SELECT AVG(total_spent) FROM CustomerSummary WHERE total_spent IS NOT NULL
    )
ORDER BY 
    total_supplier_cost DESC, customer_order_rank ASC;
