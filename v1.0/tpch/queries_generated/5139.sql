WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
), 
TopCustomers AS (
    SELECT 
        rc.c_custkey, 
        rc.c_name, 
        na.n_name AS nation_name, 
        rc.total_spent
    FROM 
        RankedCustomers rc
    JOIN 
        nation na ON rc.c_nationkey = na.n_nationkey
    WHERE 
        rc.spend_rank <= 5
), 
PartSuppliers AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_name, 
        s.s_name, 
        ps.ps_supplycost 
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 0
), 
TotalSpentOnParts AS (
    SELECT 
        rc.c_custkey, 
        pc.p_name, 
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_spent_on_parts
    FROM 
        RankedCustomers rc
    JOIN 
        orders o ON rc.c_custkey = o.o_custkey
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN 
        PartSuppliers pc ON li.l_partkey = pc.ps_partkey 
    WHERE 
        li.l_returnflag = 'N'
    GROUP BY 
        rc.c_custkey, pc.p_name
) 
SELECT 
    tc.c_name, 
    tc.nation_name, 
    p.p_name, 
    ts.total_spent, 
    tsp.total_spent_on_parts
FROM 
    TopCustomers tc
JOIN 
    TotalSpentOnParts tsp ON tc.c_custkey = tsp.c_custkey
JOIN 
    part p ON tsp.p_name = p.p_name
ORDER BY 
    tc.nation_name, tc.total_spent DESC, tsp.total_spent_on_parts DESC;
