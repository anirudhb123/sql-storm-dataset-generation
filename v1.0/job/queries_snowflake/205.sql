
WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_count_rank
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),

LatestMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        actor_count_rank <= 5
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    lm.title,
    lm.production_year,
    COALESCE(mk.keywords, 'No keywords') AS keywords,
    COALESCE(aka.name, 'Unknown') AS famous_actor,
    COUNT(DISTINCT ci.id) AS cast_count
FROM 
    LatestMovies lm
LEFT JOIN 
    MovieKeywords mk ON lm.movie_id = mk.movie_id
LEFT JOIN 
    cast_info ci ON lm.movie_id = ci.movie_id
LEFT JOIN 
    aka_name aka ON ci.person_id = aka.person_id AND aka.md5sum IS NOT NULL
WHERE 
    lm.production_year > 2000
GROUP BY 
    lm.title, lm.production_year, mk.keywords, aka.name
ORDER BY 
    lm.production_year DESC, cast_count DESC;
