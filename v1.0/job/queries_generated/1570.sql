WITH ActorMovies AS (
    SELECT 
        ak.name AS actor_name, 
        t.title AS movie_title, 
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY ak.person_id ORDER BY t.production_year DESC) AS recent_movie_rank
    FROM 
        aka_name ak 
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title t ON ci.movie_id = t.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        movie_keyword mk 
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    am.actor_name, 
    am.movie_title, 
    am.production_year, 
    COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
    COUNT(DISTINCT ci2.person_id) AS co_actors_count,
    AVG(CASE WHEN ci2.role_id IS NOT NULL THEN ci2.nr_order ELSE NULL END) AS avg_role_order
FROM 
    ActorMovies am
LEFT JOIN 
    cast_info ci ON am.movie_title = ci.movie_id
LEFT JOIN 
    cast_info ci2 ON ci2.movie_id = ci.movie_id AND ci2.person_id != ci.person_id
LEFT JOIN 
    MovieKeywords mk ON am.movie_title = mk.movie_id
WHERE 
    am.recent_movie_rank = 1 
    AND am.production_year >= 2000 
    AND (am.actor_name IS NOT NULL OR mk.keyword_list IS NOT NULL)
GROUP BY 
    am.actor_name, am.movie_title, am.production_year, mk.keyword_list
ORDER BY 
    am.production_year DESC, am.actor_name;
