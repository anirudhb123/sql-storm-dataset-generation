WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY COUNT(mk.keyword_id) DESC) AS keyword_rank
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
PopularActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(ci.movie_id) > 5
),
TitleWithActors AS (
    SELECT 
        rt.title_id,
        rt.title,
        rt.production_year,
        pa.name AS actor_name
    FROM 
        RankedMovies rt
    JOIN 
        cast_info ci ON rt.title_id = ci.movie_id
    JOIN 
        PopularActors pa ON ci.person_id = pa.person_id
    WHERE 
        rt.keyword_rank <= 3
)
SELECT 
    t.title,
    t.production_year,
    STRING_AGG(a.actor_name, ', ') AS top_actors
FROM 
    TitleWithActors t
GROUP BY 
    t.title, t.production_year
ORDER BY 
    t.production_year DESC, 
    COUNT(a.actor_name) DESC;
