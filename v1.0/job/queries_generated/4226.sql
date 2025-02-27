WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        STRING_AGG(DISTINCT ka.name, ', ') AS actors_list,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS actress_rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name ka ON ci.person_id = ka.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS associated_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.total_actors,
    rm.actors_list,
    COALESCE(mk.associated_keywords, 'No Keywords') AS associated_keywords
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
WHERE 
    rm.actress_rank <= 5
ORDER BY 
    rm.production_year ASC, 
    rm.total_actors DESC;
