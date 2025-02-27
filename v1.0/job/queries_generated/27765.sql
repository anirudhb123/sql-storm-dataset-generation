WITH TitleInfo AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ct.kind AS company_type,
        ci.role AS person_role
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_type ct ON mc.company_type_id = ct.id
    JOIN cast_info ci ON t.id = ci.movie_id
    WHERE t.production_year >= 2000
),

ActorAwards AS (
    SELECT 
        aka.name AS actor_name, 
        COUNT(DISTINCT ci.movie_id) AS movie_count, 
        ARRAY_AGG(DISTINCT ti.title) AS movie_titles,
        ARRAY_AGG(DISTINCT ti.keyword) AS associated_keywords
    FROM aka_name aka
    JOIN cast_info ci ON aka.person_id = ci.person_id
    JOIN TitleInfo ti ON ci.movie_id = ti.title_id
    GROUP BY aka.name
    HAVING movie_count > 5
)

SELECT 
    actor_name,
    movie_count,
    movie_titles,
    associated_keywords
FROM ActorAwards
ORDER BY movie_count DESC
LIMIT 10;

This SQL query benchmarks string processing across several tables by analyzing titles, actors, and keywords. It aggregates data related to actors who have significantly contributed to movies in the 2000s, filtering for those involved with more than five films. The output includes the actor's name, the number of movies they've appeared in, a list of those movie titles, and the associated keywords for further insight.
