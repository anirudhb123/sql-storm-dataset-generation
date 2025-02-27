WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(s.s_acctbal) AS avg_acct_balance,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
SuppliersWithHighOrderCount AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        co.order_count,
        rs.total_avail_qty,
        rs.avg_acct_balance
    FROM
        RankedSuppliers rs
    JOIN
        CustomerOrders co ON rs.s_nationkey = co.c_custkey 
    WHERE
        co.order_count > 5
)
SELECT
    s.s_name AS Supplier_Name,
    s.total_avail_qty AS Total_Available_Quantity,
    ROUND(s.avg_acct_balance, 2) AS Average_Account_Balance,
    c.order_count AS Number_of_Orders
FROM
    SuppliersWithHighOrderCount s
JOIN
    customer c ON s.s_nationkey = c.c_nationkey
ORDER BY
    s.total_avail_qty DESC, s.avg_acct_balance DESC;
