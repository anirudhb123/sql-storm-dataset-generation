WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        t.phonetic_code,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rank
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieAssociations AS (
    SELECT  
        ci.person_id,
        ci.movie_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        kt.keyword AS movie_keyword
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        title t ON t.id = ci.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    LEFT JOIN 
        keyword kt ON kt.id = mk.keyword_id
    WHERE 
        a.name IS NOT NULL
),
InfomationStatistics AS (
    SELECT 
        ai.person_id,
        COUNT(DISTINCT ai.movie_id) AS movie_count,
        STRING_AGG(DISTINCT ai.movie_keyword, ', ') AS keywords
    FROM 
        ActorMovieAssociations ai
    GROUP BY 
        ai.person_id
)
SELECT 
    a.person_id,
    a.actor_name,
    COUNT(DISTINCT a.movie_id) AS total_movies,
    STRING_AGG(DISTINCT a.movie_title, '; ') AS titles,
    STRING_AGG(DISTINCT a.production_year::TEXT, ', ') AS production_years,
    STRING_AGG(DISTINCT k.keyword, ', ') AS all_keywords
FROM 
    ActorMovieAssociations a
LEFT JOIN 
    InfomationStatistics is ON a.person_id = is.person_id
LEFT JOIN 
    movie_keyword mk ON a.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
GROUP BY 
    a.person_id, a.actor_name
HAVING 
    COUNT(DISTINCT a.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;
