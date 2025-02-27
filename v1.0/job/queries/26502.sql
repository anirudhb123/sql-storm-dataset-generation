
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        title m
    JOIN 
        movie_companies mc ON m.id = mc.movie_id
    JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        c.country_code = 'USA'
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),
RankedActors AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT m.id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        title m ON ci.movie_id = m.id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        a.person_id, a.name
    HAVING 
        COUNT(DISTINCT m.id) >= 3
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    rm.actors,
    ra.name AS top_actor,
    ra.movie_count
FROM 
    RankedMovies rm
JOIN 
    RankedActors ra ON rm.actors LIKE '%' || ra.name || '%'
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC;
