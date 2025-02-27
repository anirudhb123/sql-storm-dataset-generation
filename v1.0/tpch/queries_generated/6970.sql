WITH RankedCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
), 
TopCustomers AS (
    SELECT 
        rc.c_custkey, 
        rc.c_name, 
        rc.total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        RankedCustomers rc
    JOIN 
        orders o ON rc.c_custkey = o.o_custkey
    WHERE 
        rc.spend_rank <= 10
    GROUP BY 
        rc.c_custkey, rc.c_name, rc.total_spent
), 
CustomerSupplierPart AS (
    SELECT 
        tc.c_custkey, 
        tc.c_name, 
        s.s_suppkey, 
        p.p_partkey, 
        p.p_name, 
        ps.ps_supplycost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        RankedCustomers rc ON rc.c_custkey = (
            SELECT 
                o.o_custkey 
            FROM 
                orders o 
            JOIN 
                lineitem li ON o.o_orderkey = li.l_orderkey 
            WHERE 
                li.l_partkey = ps.ps_partkey 
            LIMIT 1
        )
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        TopCustomers tc ON tc.c_custkey = rc.c_custkey
)
SELECT 
    tc.c_name, 
    COUNT(DISTINCT p.p_partkey) AS total_parts_supplied, 
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM 
    CustomerSupplierPart cs
JOIN 
    TopCustomers tc ON cs.c_custkey = tc.c_custkey
GROUP BY 
    tc.c_name
ORDER BY 
    total_parts_supplied DESC, 
    total_supply_cost DESC
LIMIT 5;
