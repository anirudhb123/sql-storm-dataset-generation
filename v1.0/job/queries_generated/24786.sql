WITH RankedTitles AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS title_rank,
        COUNT(*) OVER (PARTITION BY a.id) AS title_count
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.id = t.id
    WHERE 
        t.production_year IS NOT NULL
),
HighRankTitles AS (
    SELECT 
        aka_id,
        title,
        production_year
    FROM 
        RankedTitles
    WHERE 
        title_rank = 1
),
TitleInfo AS (
    SELECT 
        ht.aka_id,
        ht.title,
        ht.production_year,
        c.role_id,
        r.role
    FROM 
        HighRankTitles ht
    LEFT JOIN 
        cast_info c ON ht.aka_id = c.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(m.id) AS movie_count
    FROM 
        movie_companies m 
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
    GROUP BY 
        m.movie_id, c.name, ct.kind
),
FullCastInfo AS (
    SELECT 
        ti.aka_id,
        ti.title,
        ti.production_year,
        ci.company_name,
        ci.company_type,
        COALESCE(SUM(CASE WHEN c.nr_order IS NULL THEN 1 ELSE 0 END), 0) AS null_orders_count
    FROM 
        TitleInfo ti
    LEFT JOIN 
        CompanyInfo ci ON ti.aka_id = ci.movie_id
    LEFT JOIN 
        cast_info c ON ti.aka_id = c.person_id
    WHERE 
        ti.title IS NOT NULL OR ci.company_name IS NOT NULL
    GROUP BY 
        ti.aka_id, ti.title, ti.production_year, ci.company_name, ci.company_type
)
SELECT 
    f.aka_id,
    f.title,
    f.production_year,
    f.company_name,
    f.company_type,
    f.null_orders_count,
    CASE 
        WHEN f.null_orders_count > 0 THEN 'Contains NULL Orders'
        ELSE 'No NULL Orders'
    END AS order_status
FROM 
    FullCastInfo f
WHERE 
    f.production_year = (SELECT MAX(production_year) FROM HighRankTitles)
ORDER BY 
    f.production_year DESC, f.aka_id;
