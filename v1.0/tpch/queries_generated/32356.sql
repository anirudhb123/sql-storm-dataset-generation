WITH RECURSIVE SalesCTE AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS spending_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= '2023-01-01'
    GROUP BY
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rn
    FROM
        SalesCTE
    JOIN
        customer c ON SalesCTE.c_custkey = c.c_custkey
    WHERE
        spending_rank <= 3
),
RelevantSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(ps.ps_availqty) > 100
),
FinalResult AS (
    SELECT
        tc.c_name AS customer_name,
        tc.c_acctbal AS customer_balance,
        rs.s_name AS supplier_name,
        rs.total_supplycost AS supplier_cost
    FROM
        TopCustomers tc
    LEFT JOIN
        lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey)
    LEFT JOIN
        partsupp ps ON ps.ps_partkey = l.l_partkey
    LEFT JOIN
        RelevantSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
)
SELECT
    customer_name,
    customer_balance,
    supplier_name,
    COALESCE(supplier_cost, 0) AS supplier_cost,
    CASE 
        WHEN customer_balance < 1000 THEN 'Low Balance'
        WHEN customer_balance BETWEEN 1000 AND 5000 THEN 'Medium Balance'
        ELSE 'High Balance'
    END AS balance_category
FROM
    FinalResult
WHERE
    supplier_cost IS NOT NULL OR customer_balance > 2000
ORDER BY
    customer_balance DESC, supplier_cost ASC;
