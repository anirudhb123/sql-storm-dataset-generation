WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count,
        CASE 
            WHEN m.production_year >= 2000 AND k.keyword IS NOT NULL THEN 'Modern Era' 
            ELSE 'Classic Era' 
        END AS era 
    FROM 
        aka_title m
    INNER JOIN 
        cast_info c ON m.id = c.movie_id
    INNER JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_names,
        keyword_count,
        era,
        ROW_NUMBER() OVER (PARTITION BY era ORDER BY keyword_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    actor_names,
    keyword_count,
    era
FROM 
    FilteredMovies
WHERE 
    rank <= 5
ORDER BY 
    era ASC, 
    keyword_count DESC;
