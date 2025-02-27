WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.id) AS cast_member_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        m.id, m.title, m.production_year
),
PopularKeywords AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        COUNT(mk.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id, k.keyword
    HAVING 
        COUNT(mk.id) > 5
),
EnrichedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_member_count,
        rm.actor_names,
        COALESCE(pk.keyword, 'No Keywords') AS popular_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        PopularKeywords pk ON rm.movie_id = pk.movie_id
)
SELECT 
    ed.movie_id,
    ed.title,
    ed.production_year,
    ed.cast_member_count,
    ed.actor_names,
    ed.popular_keyword
FROM 
    EnrichedData ed
ORDER BY 
    ed.production_year DESC, 
    ed.cast_member_count DESC
LIMIT 10;
