
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        mt.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mt
    JOIN 
        keyword k ON mt.keyword_id = k.id
    GROUP BY 
        mt.movie_id
),
CastDetails AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COALESCE(r.role, 'Unknown') AS role
    FROM 
        cast_info c
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        role_type r ON c.role_id = r.id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    COALESCE(k.keywords, 'No keywords') AS keywords,
    cd.actor_name,
    cd.role,
    cc.company_count,
    rt.year_rank
FROM 
    RankedTitles rt
LEFT JOIN 
    MoviesWithKeywords k ON rt.title_id = k.movie_id
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    CompanyCounts cc ON rt.title_id = cc.movie_id
WHERE 
    rt.year_rank <= 5
ORDER BY 
    rt.production_year DESC, rt.year_rank, rt.title;
