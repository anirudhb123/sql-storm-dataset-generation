WITH RankedTitles AS (
    SELECT 
        a.title,
        a.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY LENGTH(a.title) DESC) AS title_length_rank,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY a.production_year DESC) AS year_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        a.production_year >= 2000
),
FilteredTitles AS (
    SELECT 
        rt.title,
        rt.production_year,
        rt.keyword
    FROM 
        RankedTitles rt
    WHERE 
        rt.title_length_rank = 1 AND rt.year_rank = 1
),
ActorTitles AS (
    SELECT 
        p.name AS actor_name,
        ft.title AS movie_title,
        ft.production_year
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        FilteredTitles ft ON ci.movie_id = ft.id
)
SELECT 
    actor_name,
    COUNT(movie_title) AS total_movies,
    STRING_AGG(movie_title, ', ') AS movies
FROM 
    ActorTitles
GROUP BY 
    actor_name
HAVING 
    COUNT(movie_title) > 1
ORDER BY 
    total_movies DESC;
