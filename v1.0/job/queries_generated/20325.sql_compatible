
WITH RecursiveMovieCast AS (
    SELECT 
        ca.movie_id, 
        a.name AS actor_name, 
        ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY a.name) AS actor_order
    FROM 
        cast_info ca
    JOIN 
        aka_name a ON ca.person_id = a.person_id
), ActorCount AS (
    SELECT 
        movie_id, 
        COUNT(*) AS actor_count
    FROM 
        RecursiveMovieCast
    GROUP BY 
        movie_id
), MovieDetails AS (
    SELECT 
        t.title, 
        t.production_year, 
        m.movie_id, 
        COALESCE(c.name, 'Unknown') AS company_name
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies m ON t.id = m.movie_id
    LEFT JOIN 
        company_name c ON m.company_id = c.id
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
), KeywordStatistics AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    md.title,
    md.production_year,
    ac.actor_count,
    ks.keywords,
    md.company_name,
    CASE 
        WHEN ac.actor_count > 5 THEN 'Ensemble Cast' 
        ELSE 'Small Cast' 
    END AS cast_type,
    CASE 
        WHEN md.production_year IS NULL THEN 'Year Unknown'
        ELSE CAST(md.production_year AS VARCHAR) 
    END AS year_string
FROM 
    MovieDetails md
LEFT JOIN 
    ActorCount ac ON md.movie_id = ac.movie_id
LEFT JOIN 
    KeywordStatistics ks ON md.movie_id = ks.movie_id
WHERE 
    md.company_name IS NOT NULL OR ac.actor_count IS NULL
ORDER BY 
    md.production_year DESC, 
    ac.actor_count ASC NULLS FIRST
LIMIT 100;
