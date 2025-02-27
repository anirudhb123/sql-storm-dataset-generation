WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
), 
ActorInfo AS (
    SELECT 
        a.person_id, 
        a.name, 
        COALESCE(ci.person_role_id, r.id) AS role_id,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        title m ON ci.movie_id = m.id
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        a.person_id, a.name, ci.person_role_id, r.id
), 
MovieGenres AS (
    SELECT 
        mt.movie_id, 
        STRING_AGG(kg.keyword, ', ') AS genres
    FROM 
        movie_keyword mk
    JOIN 
        keyword kg ON mk.keyword_id = kg.id
    JOIN 
        aka_title mt ON mk.movie_id = mt.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    ai.name AS actor_name,
    ai.movie_count,
    COALESCE(mg.genres, 'No genre available') AS genres,
    CASE 
        WHEN rm.year_rank <= 5 THEN 'Top 5 Movies of the Year'
        ELSE 'Other Movies'
    END AS movie_ranking
FROM 
    RankedMovies rm
JOIN 
    cast_info ci ON rm.movie_id = ci.movie_id
JOIN 
    ActorInfo ai ON ci.person_id = ai.person_id
LEFT JOIN 
    MovieGenres mg ON rm.movie_id = mg.movie_id
WHERE 
    rm.production_year IS NOT NULL
    AND (ai.movie_count > 1 OR ai.role_id IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    ai.movie_count DESC;
