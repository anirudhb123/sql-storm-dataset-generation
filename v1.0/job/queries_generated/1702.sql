WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        a.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc 
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        c.country_code = 'USA'
)
SELECT 
    rt.title,
    rt.production_year,
    ac.actor_count,
    cm.company_name,
    cm.company_type,
    COALESCE(NULLIF(rt.title_rank, 1), 'First Title') AS title_rank_desc
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorCounts ac ON rt.title = (
        SELECT 
            t.title 
        FROM 
            title t 
        WHERE 
            t.id IN (
                SELECT movie_id FROM cast_info WHERE person_id IN (SELECT id FROM aka_name WHERE name LIKE 'J%')
            )
        LIMIT 1
    ) 
LEFT JOIN 
    CompanyMovies cm ON rt.production_year IN (
        SELECT 
            DISTINCT production_year 
        FROM 
            aka_title 
        WHERE 
            title LIKE '%Adventure%'
    )
WHERE 
    rt.title_rank <= 5
ORDER BY 
    rt.production_year DESC, 
    rt.title;
