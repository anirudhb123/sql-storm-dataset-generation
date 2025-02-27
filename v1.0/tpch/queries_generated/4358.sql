WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS Rank
    FROM 
        customer c
),
NationSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
        SUM(s.s_acctbal) AS TotalAcctBal
    FROM 
        nation n
        LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_linenumber) AS NumberOfItems
    FROM 
        orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' 
        AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    n.n_name AS Nation,
    rs.c_name AS TopCustomer,
    rs.c_acctbal AS TopCustomerAcctBal,
    ods.TotalRevenue AS CustomerRevenue,
    ns.SupplierCount,
    ns.TotalAcctBal
FROM 
    RankedCustomers rs
    JOIN NationSummary ns ON rs.c_custkey IN (
            SELECT 
                o.o_custkey 
            FROM 
                orders o 
            WHERE 
                o.o_totalprice >= 1000
            INTERSECT
            SELECT 
                DISTINCT c.c_custkey 
            FROM 
                customer c 
            WHERE 
                c.c_nationkey = ns.n_nationkey
    )
    LEFT JOIN OrderDetails ods ON rs.c_custkey = ods.o_custkey
    JOIN nation n ON rs.c_nationkey = n.n_nationkey
WHERE 
    rs.Rank = 1
ORDER BY 
    ns.TotalAcctBal DESC, 
    CustomerRevenue DESC;
