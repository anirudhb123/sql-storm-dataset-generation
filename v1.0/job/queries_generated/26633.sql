WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year, 
        t.kind_id, 
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_casting_rating,
        COUNT(DISTINCT ci.person_id) AS total_cast_count,
        COUNT(DISTINCT mk.keyword) AS total_keywords
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    GROUP BY 
        t.id
    HAVING 
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) > 0.5
),
PopularActors AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT cc.movie_id) AS movies_count,
        AVG(ca.nr_order) AS avg_order
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    JOIN 
        complete_cast cc ON ca.movie_id = cc.movie_id
    GROUP BY 
        a.id
    HAVING 
        COUNT(DISTINCT cc.movie_id) > 3
)
SELECT 
    rm.title AS movie_title,
    rm.production_year,
    COUNT(DISTINCT pa.actor_name) AS num_popular_actors,
    rm.total_cast_count,
    rm.total_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    PopularActors pa ON pa.movies_count > 3 AND pa.avg_order < 2
GROUP BY 
    rm.title, rm.production_year, rm.total_cast_count, rm.total_keywords
ORDER BY 
    rm.total_cast_count DESC, rm.production_year DESC;
