WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.total_spent,
        c.order_count,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrderTotals c
    WHERE 
        c.total_spent > 10000
),
FilteredSuppliers AS (
    SELECT 
        spd.s_suppkey,
        spd.s_name,
        spd.p_partkey,
        spd.p_name,
        spd.ps_availqty,
        spd.ps_supplycost
    FROM 
        SupplierPartDetails spd
    JOIN 
        TopCustomers tc ON spd.s_suppkey IN (
            SELECT 
                ps.ps_suppkey 
            FROM 
                partsupp ps 
            JOIN 
                orders o ON ps.ps_partkey IN (
                    SELECT 
                        l.l_partkey 
                    FROM 
                        lineitem l 
                    WHERE 
                        l.l_orderkey IN (SELECT o2.o_orderkey FROM orders o2 WHERE o2.o_custkey = tc.c_custkey)
                )
        )
),
FinalOutput AS (
    SELECT 
        fs.s_suppkey,
        fs.s_name,
        fs.p_partkey,
        fs.p_name,
        fs.ps_availqty * fs.ps_supplycost AS total_cost_value,
        fs.ps_supplycost,
        tc.total_spent
    FROM 
        FilteredSuppliers fs
    JOIN 
        TopCustomers tc ON fs.s_suppkey IN (
            SELECT 
                s.s_suppkey 
            FROM 
                supplier s 
            WHERE 
                s.s_acctbal > 500
        )
)
SELECT 
    fo.s_suppkey,
    fo.s_name,
    fo.p_partkey,
    fo.p_name,
    fo.total_cost_value,
    fo.ps_supplycost,
    fo.total_spent
FROM 
    FinalOutput fo
ORDER BY 
    fo.total_cost_value DESC
LIMIT 100;
