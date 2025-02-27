WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        a.id
), FilteredMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY actor_count DESC) as rank
    FROM 
        RankedMovies
)
SELECT 
    f.title,
    f.production_year,
    f.actor_count,
    f.actors,
    f.keywords
FROM 
    FilteredMovies f
WHERE 
    f.actor_count > 5
ORDER BY 
    f.rank
LIMIT 10;
