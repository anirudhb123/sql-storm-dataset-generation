WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
NamedActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        ak.surname_pcode,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    GROUP BY 
        ak.person_id, ak.name, ak.surname_pcode
    HAVING 
        COUNT(DISTINCT c.movie_id) > 5
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        na.name AS actor_name,
        rm.keyword,
        na.movie_count
    FROM 
        RankedMovies rm
    JOIN 
        cast_info ci ON rm.movie_id = ci.movie_id
    JOIN 
        NamedActors na ON ci.person_id = na.person_id
)
SELECT 
    mwc.title AS Movie_Title,
    mwc.production_year AS Production_Year,
    mwc.actor_name AS Actor_Name,
    mwc.keyword AS Movie_Keyword,
    CONCAT(mwc.actor_name, ' in ', mwc.title, ' - ', mwc.keyword) AS Descriptive_String
FROM 
    MoviesWithCast mwc
WHERE 
    mwc.keyword IS NOT NULL
ORDER BY 
    mwc.production_year DESC, 
    mwc.title;
