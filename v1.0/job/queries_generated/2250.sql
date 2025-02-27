WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS production_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.title, t.production_year
),
CompanyInfo AS (
    SELECT 
        m.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        aka_title m ON mc.movie_id = m.id
    GROUP BY 
        m.movie_id
),
FilteredTitles AS (
    SELECT 
        r.title,
        r.production_year,
        r.actor_count,
        ci.company_count,
        ci.companies
    FROM 
        RankedMovies r
    JOIN 
        CompanyInfo ci ON r.title = ci.movie_id
    WHERE 
        r.actor_count > 5
)

SELECT 
    ft.title,
    ft.production_year,
    ft.actor_count,
    ft.company_count,
    ft.companies,
    COALESCE(mk.keyword, 'No keywords') AS keyword
FROM 
    FilteredTitles ft
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = ft.title LIMIT 1)
WHERE 
    ft.company_count IS NOT NULL
ORDER BY 
    ft.production_year, ft.actor_count DESC;
