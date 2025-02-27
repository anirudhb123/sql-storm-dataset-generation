WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.total_cost
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 10
),
CustomerSpent AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_custkey
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.c_acctbal,
        cs.c_nationkey,
        cc.total_spent
    FROM 
        customer cs
    JOIN 
        CustomerSpent cc ON cs.c_custkey = cc.o_custkey
    WHERE 
        cc.total_spent > 10000
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    hs.s_name,
    hs.total_cost
FROM 
    TopCustomers tc
JOIN 
    HighCostSuppliers hs ON tc.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = tc.c_nationkey)
ORDER BY 
    tc.total_spent DESC, hs.total_cost DESC;
