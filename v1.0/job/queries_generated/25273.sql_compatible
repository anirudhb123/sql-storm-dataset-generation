
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id 
    GROUP BY 
        t.id, t.title, t.production_year
),

HighCastMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast <= 5
),

MovieKeywords AS (
    SELECT 
        hm.movie_id, 
        ARRAY_AGG(k.keyword) AS keywords
    FROM 
        HighCastMovies hm
    JOIN 
        movie_keyword mk ON hm.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        hm.movie_id
)

SELECT 
    hm.production_year,
    hm.title,
    hm.movie_id,
    mk.keywords,
    ak.name AS actor_name,
    COUNT(DISTINCT ci.person_id) AS total_cast
FROM 
    HighCastMovies hm
JOIN 
    complete_cast cc ON hm.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieKeywords mk ON hm.movie_id = mk.movie_id
GROUP BY 
    hm.movie_id, hm.title, hm.production_year, mk.keywords, ak.name
ORDER BY 
    hm.production_year DESC, total_cast DESC;
