WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_id) DESC) AS rank
    FROM 
        title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
ActiveActors AS (
    SELECT 
        a.person_id,
        a.name,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.movie_id) DESC) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    WHERE 
        c.movie_id IN (SELECT movie_id FROM RankedMovies WHERE rank <= 10)
    GROUP BY 
        a.person_id, a.name
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(aa.name, 'Unknown Actor') AS lead_actor,
    COALESCE(mk.keywords, 'No keywords') AS keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    ActiveActors aa ON aa.actor_rank = 1
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.cast_count > 0
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
