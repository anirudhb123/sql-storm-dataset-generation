WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS director_name,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name cn ON cn.id = mc.company_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    WHERE 
        t.production_year IS NOT NULL
        AND cn.country_code = 'USA' -- Filtering for US productions
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
FilteredRankedMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        director_name,
        keywords,
        cast_count,
        rank_per_year
    FROM 
        RankedMovies
    WHERE 
        cast_count > 5 AND rank_per_year <= 10 -- Filtering for top 10 movies with more than 5 cast members
)
SELECT 
    FR.movie_title,
    FR.production_year,
    FR.director_name,
    STRING_AGG(DISTINCT unnest(FR.keywords), ', ') AS all_keywords,
    FR.cast_count
FROM 
    FilteredRankedMovies FR
GROUP BY 
    FR.movie_id, FR.movie_title, FR.production_year, FR.director_name, FR.cast_count
ORDER BY 
    FR.production_year DESC, FR.cast_count DESC;
