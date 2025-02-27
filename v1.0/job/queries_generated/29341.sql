WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY COUNT(DISTINCT kc.keyword) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kc ON mk.keyword_id = kc.id
    GROUP BY 
        t.id
),
ActorInfo AS (
    SELECT 
        a.id AS actor_id,
        a.name,
        COUNT(DISTINCT ci.movie_id) AS movies_count,
        STRING_AGG(DISTINCT tt.title, ', ') AS movie_titles
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title tt ON ci.movie_id = tt.id
    GROUP BY 
        a.id
)
SELECT 
    ri.title_id,
    ri.title,
    ri.production_year,
    ai.actor_id,
    ai.name AS actor_name,
    ai.movies_count,
    ai.movie_titles,
    rt.keyword_count
FROM 
    RankedTitles rt
JOIN 
    ActorInfo ai ON rt.rank = 1
WHERE 
    rt.production_year >= 2000 AND 
    rt.keyword_count > 5
ORDER BY 
    rt.production_year DESC,
    ai.movies_count DESC
LIMIT 10;

This query benchmarks string processing by aggregating and joining a variety of information across multiple tables, focusing on movie titles and actor details. It ranks titles based on the count of associated keywords, collects actor information including the number of movies they have participated in, and filters these results for recent productions that have a meaningful number of keywords. The final result presents a curated list of titles with associated actor details in a structured format.
