WITH RankedMovies AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.id AS title_id,
        t.title AS movie_title,
        t.production_year,
        c.id AS cast_id,
        p.name AS person_name,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY p.name) AS actor_rank
    FROM 
        aka_name a
    JOIN 
        aka_title t ON a.person_id = t.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        name p ON c.person_id = p.id
    WHERE 
        a.name IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        m.movie_id,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY k.keyword) AS keyword_rank
    FROM 
        movie_keyword m
    JOIN 
        keyword k ON m.keyword_id = k.id
),
CombinedData AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.aka_name,
        rm.person_name,
        mk.keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
)
SELECT 
    movie_title,
    production_year,
    aka_name,
    STRING_AGG(DISTINCT person_name, ', ') AS actors,
    STRING_AGG(DISTINCT keyword, ', ') AS keywords
FROM 
    CombinedData
GROUP BY 
    movie_title, production_year, aka_name
ORDER BY 
    production_year DESC, movie_title;
