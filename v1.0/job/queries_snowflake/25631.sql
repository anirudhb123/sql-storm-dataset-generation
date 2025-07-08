
WITH RecursiveMovieList AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        a.id AS actor_id,
        COALESCE(k.keyword, 'N/A') AS keyword,
        COUNT(DISTINCT cc.id) AS cast_count
    FROM 
        aka_title AS t
    JOIN 
        cast_info AS c ON t.id = c.movie_id
    JOIN 
        aka_name AS a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword AS mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    JOIN 
        complete_cast AS cc ON t.id = cc.movie_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name, a.id, k.keyword
    ORDER BY 
        t.production_year DESC
),
TopActors AS (
    SELECT 
        actor_id,
        actor_name,
        SUM(cast_count) AS total_casts
    FROM 
        RecursiveMovieList
    GROUP BY 
        actor_id, actor_name
    ORDER BY 
        total_casts DESC
    LIMIT 10
),
MovieInfo AS (
    SELECT 
        ml.movie_id,
        ml.title,
        ml.production_year,
        ta.actor_name,
        ti.info
    FROM 
        RecursiveMovieList AS ml
    JOIN 
        TopActors AS ta ON ml.actor_id = ta.actor_id
    LEFT JOIN 
        movie_info AS ti ON ml.movie_id = ti.movie_id
    WHERE 
        ti.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
)
SELECT 
    m.title,
    m.production_year,
    m.actor_name,
    mi.info
FROM 
    MovieInfo AS mi
JOIN 
    RecursiveMovieList AS m ON mi.movie_id = m.movie_id
ORDER BY 
    m.production_year DESC, m.actor_name;
