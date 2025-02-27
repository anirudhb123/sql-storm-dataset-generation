WITH MovieActors AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        a.name AS actor_name,
        a.id AS actor_id,
        c.nr_order AS actor_order
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year > 2000  
),
AggregateCharacters AS (
    SELECT 
        ma.movie_id,
        ma.movie_title,
        STRING_AGG(ma.actor_name, ', ' ORDER BY ma.actor_order) AS actor_list,
        COUNT(ma.actor_id) AS total_actors
    FROM 
        MovieActors ma
    GROUP BY 
        ma.movie_id, ma.movie_title
),
KeywordMovieCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
FinalBenchmark AS (
    SELECT 
        a.movie_id,
        a.movie_title,
        a.actor_list,
        a.total_actors,
        COALESCE(kmc.keyword_count, 0) AS keyword_count
    FROM 
        AggregateCharacters a
    LEFT JOIN 
        KeywordMovieCounts kmc ON a.movie_id = kmc.movie_id
)
SELECT 
    movie_id,
    movie_title,
    actor_list,
    total_actors,
    keyword_count
FROM 
    FinalBenchmark
ORDER BY 
    total_actors DESC, keyword_count DESC;