WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND 
        o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        rc.c_custkey, 
        rc.c_name, 
        rc.total_spent, 
        n.n_name AS nation_name
    FROM 
        RankedCustomers rc
    JOIN 
        nation n ON rc.c_nationkey = n.n_nationkey
    WHERE 
        rc.rank <= 5
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, s.s_suppkey, s.s_name
)
SELECT 
    tc.c_name, 
    tc.total_spent, 
    tp.s_name AS supplier_name, 
    SUM(lp.l_quantity) AS total_ordered,
    MAX(lp.l_extendedprice) AS max_price,
    AVG(lp.l_discount) AS avg_discount
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
JOIN 
    SupplierParts tp ON lp.l_partkey = tp.ps_partkey
WHERE 
    lp.l_shipdate >= DATE '2022-01-01' AND 
    lp.l_shipdate < DATE '2023-01-01'
GROUP BY 
    tc.c_name, tc.total_spent, tp.s_name
ORDER BY 
    tc.total_spent DESC, total_ordered DESC
LIMIT 10;
