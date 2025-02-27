
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank,
        COUNT(c.id) OVER (PARTITION BY t.id) AS cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year > 2000
        AND (k.keyword IS NOT NULL OR t.title LIKE '%Saga%')
),

ActorInfo AS (
    SELECT 
        a.person_id,
        a.name AS actor_name,
        COUNT(ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies,
        MAX(pi.info) AS notable_info
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info ci ON a.person_id = ci.person_id
    LEFT JOIN 
        aka_title t ON ci.movie_id = t.id
    LEFT JOIN 
        person_info pi ON a.person_id = pi.person_id
    WHERE 
        pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Award')
    GROUP BY 
        a.person_id, a.name
)

SELECT 
    rm.title,
    rm.production_year,
    rm.keyword,
    ai.actor_name,
    ai.movie_count,
    ai.movies,
    COALESCE(ai.notable_info, 'Unknown') AS notable_info
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorInfo ai ON rm.movie_id IN (
        SELECT ci.movie_id
        FROM cast_info ci
        WHERE ci.person_id = ai.person_id
    )
WHERE 
    rm.rank <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.title
LIMIT 100;
