
WITH ActorMovies AS (
    SELECT 
        a.id AS actor_id, 
        a.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year,
        c.role_id,
        c.nr_order,
        c.movie_id
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    JOIN 
        aka_title t ON c.movie_id = t.movie_id
    WHERE 
        t.production_year >= 2000
),
KeywordMovies AS (
    SELECT 
        m.movie_id, 
        k.keyword 
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    WHERE 
        k.keyword LIKE '%action%' OR k.keyword LIKE '%drama%'
),
CompleteCast AS (
    SELECT 
        cm.movie_id, 
        COUNT(cm.subject_id) AS total_cast
    FROM 
        complete_cast cm
    GROUP BY 
        cm.movie_id
),
MovieDetails AS (
    SELECT 
        am.actor_name, 
        am.movie_title, 
        am.production_year, 
        km.keyword,
        cc.total_cast
    FROM 
        ActorMovies am
    JOIN 
        KeywordMovies km ON am.movie_id = km.movie_id
    JOIN 
        CompleteCast cc ON am.movie_id = cc.movie_id
)
SELECT 
    actor_name, 
    movie_title, 
    production_year, 
    STRING_AGG(DISTINCT keyword, ', ') AS keywords, 
    total_cast
FROM 
    MovieDetails
GROUP BY 
    actor_name, 
    movie_title, 
    production_year, 
    total_cast
ORDER BY 
    production_year DESC, 
    actor_name, 
    movie_title;
