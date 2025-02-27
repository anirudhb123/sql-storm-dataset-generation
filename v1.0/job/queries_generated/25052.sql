WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        a.name AS actor_name,
        t.kind AS title_kind,
        ROW_NUMBER() OVER (PARTITION BY at.movie_id ORDER BY a.name) AS actor_rank,
        at.production_year,
        COUNT(*) OVER (PARTITION BY at.movie_id) AS actor_count
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        kind_type t ON at.kind_id = t.id
    WHERE 
        at.production_year BETWEEN 2000 AND 2020
),

MovieKeywordStats AS (
    SELECT 
        at.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id
)

SELECT 
    rm.movie_title,
    rm.actor_name,
    rm.title_kind,
    rm.production_year,
    rm.actor_count,
    mk.keywords,
    mk.keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywordStats mk ON mk.movie_id = rm.movie_id
WHERE 
    rm.actor_rank <= 5
ORDER BY 
    rm.production_year DESC, 
    mk.keyword_count DESC,
    rm.movie_title;
