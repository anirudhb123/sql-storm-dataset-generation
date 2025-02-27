WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'F')
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
CustomerValue AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        SUM(o.o_totalprice) > 1000
),
LineItemAnalysis AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        l.l_partkey
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(l.avg_quantity, 0) AS avg_quantity,
    COALESCE(s.total_cost, 0) AS supplier_total_cost,
    c.total_spent,
    RANK() OVER (ORDER BY COALESCE(c.total_spent, 0) DESC) AS customer_rank
FROM 
    part p
LEFT JOIN 
    LineItemAnalysis l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    SupplierParts s ON p.p_partkey = s.ps_partkey
LEFT JOIN 
    CustomerValue c ON c.c_custkey IN (
        SELECT DISTINCT c.c_custkey
        FROM 
            customer c 
        JOIN 
            orders o ON c.c_custkey = o.o_custkey
        WHERE 
            o.o_orderdate = (
                SELECT MAX(o2.o_orderdate)
                FROM orders o2
                WHERE o2.o_custkey = c.c_custkey
            )
    )
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10)
OR 
    EXISTS (
        SELECT 1 
        FROM region r 
        JOIN nation n ON r.r_regionkey = n.n_regionkey 
        JOIN supplier s ON s.s_nationkey = n.n_nationkey 
        WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
    )
ORDER BY 
    customer_rank, p.p_partkey;
