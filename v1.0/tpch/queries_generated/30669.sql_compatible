
WITH RECURSIVE SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
), 
TopCustomer AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), 
RankingNation AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        SUM(s.s_acctbal) AS total_acct_bal,
        RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS nation_rank
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SALE.total_sales, 0) AS total_sales,
    COALESCE(CUST.total_spent, 0) AS total_spent,
    NATION.n_name,
    NATION.total_acct_bal,
    NATION.nation_rank
FROM 
    part p
LEFT JOIN 
    (SELECT o.o_orderkey, s.total_sales 
     FROM SalesCTE s
     JOIN orders o ON s.o_orderkey = o.o_orderkey) SALE ON SALE.o_orderkey = p.p_partkey
LEFT JOIN 
    (SELECT c.c_custkey, c.total_spent 
     FROM TopCustomer c) CUST ON CUST.c_custkey = p.p_partkey
JOIN 
    (SELECT n.n_nationkey, n.n_name, n.total_acct_bal, n.nation_rank 
     FROM RankingNation n) NATION ON NATION.n_nationkey = (SELECT n_nationkey FROM supplier WHERE s_suppkey = p.p_partkey)
WHERE 
    p.p_retailprice IS NOT NULL 
    AND (NATION.nation_rank <= 3 OR COALESCE(SALE.total_sales, 0) > 10000)
ORDER BY 
    total_sales DESC, total_spent ASC;
