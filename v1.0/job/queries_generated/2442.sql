WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
MovieDetails AS (
    SELECT 
        ct.movie_id,
        GROUP_CONCAT(DISTINCT ak.name ORDER BY ak.name) AS actor_names,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    JOIN 
        aka_name ak ON ak.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = ci.movie_id
    GROUP BY 
        ct.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    md.actor_names,
    md.keyword_count,
    md.company_count
FROM 
    RankedTitles rt
LEFT JOIN 
    MovieDetails md ON md.movie_id = rt.title_id
WHERE 
    rt.year_rank = 1 
    AND (md.keyword_count > 0 OR md.company_count IS NULL)
ORDER BY 
    rt.production_year DESC, 
    md.actor_names;
