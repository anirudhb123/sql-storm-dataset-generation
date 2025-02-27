WITH RECURSIVE SalesCTE AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
), RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        total_sales,
        sales_rank,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn
    FROM 
        SalesCTE
), SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, r.r_name
), FinalOutput AS (
    SELECT 
        rs.c_custkey,
        rs.c_name,
        COALESCE(sr.total_supply_cost, 0) AS total_supply_cost,
        CASE 
            WHEN rs.total_sales > COALESCE(sr.total_supply_cost, 0) THEN 'Profit'
            ELSE 'Loss'
        END AS business_state
    FROM 
        RankedSales rs
    LEFT JOIN 
        SupplierRegion sr ON sr.nation_name = (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = rs.c_custkey))
)
SELECT 
    f.c_custkey,
    f.c_name,
    f.total_supply_cost,
    f.business_state
FROM 
    FinalOutput f
WHERE 
    f.business_state = 'Profit'
ORDER BY 
    f.total_supply_cost DESC
LIMIT 10;
