
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS year_rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCount AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
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
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FullMovieInfo AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COALESCE(ac.actor_count, 0) AS actor_count,
        ci.company_name,
        ci.company_type,
        ki.keywords
    FROM 
        title t
    LEFT JOIN 
        ActorCount ac ON t.id = ac.movie_id
    LEFT JOIN 
        CompanyInfo ci ON t.id = ci.movie_id
    LEFT JOIN 
        KeywordInfo ki ON t.id = ki.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_count,
    f.company_name,
    f.company_type,
    f.keywords,
    CASE 
        WHEN f.actor_count > 5 THEN 'Star-studded'
        WHEN f.actor_count = 0 THEN 'No cast'
        ELSE 'Regular cast' 
    END AS cast_description,
    CASE 
        WHEN f.production_year IS NOT NULL THEN 
            (SELECT STRING_AGG(rt.title, ', ') 
             FROM RankedTitles rt 
             WHERE rt.production_year = f.production_year 
             AND rt.year_rank <= 3)
        ELSE 'N/A'
    END AS top_3_titles_same_year
FROM 
    FullMovieInfo f
WHERE 
    f.production_year BETWEEN 2000 AND 2023
    AND (f.company_type IS NULL OR f.company_type LIKE '%Production%')
ORDER BY 
    f.production_year DESC, 
    f.actor_count DESC, 
    f.title;
