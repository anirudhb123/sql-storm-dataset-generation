WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        c.name AS director_name,
        COUNT(mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(mk.keyword) DESC) AS rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        cast_info ci ON a.id = ci.movie_id
    JOIN 
        aka_name cn ON ci.person_id = cn.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        rt.role = 'director'
    GROUP BY 
        a.title, a.production_year, cn.name
),
TopRankedMovies AS (
    SELECT 
        movie_title,
        production_year,
        director_name,
        keyword_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    TRIM(movie_title) AS "Top Movie Title",
    production_year AS "Year",
    TRIM(director_name) AS "Director",
    keyword_count AS "Keyword Count"
FROM 
    TopRankedMovies
ORDER BY 
    production_year DESC, keyword_count DESC;
