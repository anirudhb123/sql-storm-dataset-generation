WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS actor_count,
        COUNT(c.person_id) AS total_actors
    FROM 
        aka_title m
    LEFT JOIN 
        complete_cast c ON m.id = c.movie_id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.id, m.title, m.production_year
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        AVG(CASE WHEN p.info IS NOT NULL THEN LENGTH(p.info) ELSE 0 END) AS avg_info_length
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword k ON ci.movie_id = k.movie_id
    LEFT JOIN 
        person_info p ON a.person_id = p.person_id
    GROUP BY 
        a.name
),
SignificantMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.total_actors,
        ad.actor_name,
        ad.keyword_count,
        ad.avg_info_length
    FROM 
        RankedMovies rm
    JOIN 
        ActorDetails ad ON rm.actor_count > 5 AND rm.total_actors > 10
    WHERE 
        rm.actor_count <= 10
    ORDER BY 
        rm.production_year DESC, rm.total_actors DESC
)
SELECT 
    sm.title,
    sm.production_year,
    sm.total_actors,
    sm.actor_name,
    sm.keyword_count,
    sm.avg_info_length
FROM 
    SignificantMovies sm
WHERE 
    (sm.keyword_count IS NULL OR sm.avg_info_length > 100)
ORDER BY 
    sm.production_year, sm.title;
