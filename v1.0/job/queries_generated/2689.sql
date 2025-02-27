WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank
    FROM 
        title t
),
joinedMovies AS (
    SELECT
        t.title,
        t.production_year,
        a.name AS actor_name,
        ct.kind AS company_type,
        COALESCE(mk.keyword, 'No Keywords') AS keyword
    FROM 
        RankedTitles rt
    LEFT JOIN 
        cast_info ci ON ci.movie_id = rt.title_id
    LEFT JOIN 
        aka_name a ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rt.title_id
    LEFT JOIN 
        company_type ct ON ct.id = mc.company_type_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rt.title_id
    WHERE 
        rt.rank <= 5
),
AggregatedInfo AS (
    SELECT 
        title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS all_actors,
        STRING_AGG(DISTINCT company_type, ', ') AS all_company_types,
        MAX(keyword) AS primary_keyword
    FROM 
        joinedMovies
    GROUP BY 
        title, production_year
)

SELECT 
    ai.title,
    ai.production_year,
    ai.all_actors,
    ai.all_company_types,
    COALESCE(ai.primary_keyword, 'N/A') AS main_keyword
FROM 
    AggregatedInfo ai
WHERE 
    ai.production_year IS NOT NULL
ORDER BY 
    ai.production_year DESC, ai.title ASC;
