
WITH RecentMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year >= 2020
    GROUP BY 
        t.title, t.production_year, t.id
), ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        COUNT(DISTINCT cm.movie_id) AS movies_with_role
    FROM 
        aka_name ak
    JOIN 
        cast_info cm ON ak.person_id = cm.person_id
    WHERE 
        cm.role_id IN (SELECT id FROM role_type WHERE role LIKE 'Actor%')
    GROUP BY 
        ak.name, ak.person_id
), MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    ad.actor_name,
    ad.movies_with_role,
    mk.keywords,
    COALESCE(rm.cast_count, 0) AS cast_count
FROM 
    RecentMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.cast_count > 0 AND rm.movie_id IN (SELECT movie_id FROM movie_keyword WHERE keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%Drama%'))
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
