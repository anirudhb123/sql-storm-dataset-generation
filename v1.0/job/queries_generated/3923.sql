WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_num,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedMovies 
    WHERE 
        rank_num <= 5
),
MovieGenres AS (
    SELECT 
        m.title,
        k.keyword AS genre
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
),
FinalResults AS (
    SELECT 
        m.title,
        m.production_year,
        g.genre,
        COALESCE(SUM(CASE WHEN c.role_id IS NULL THEN 1 ELSE 0 END), 0) AS unnamed_roles,
        COUNT(c.id) AS total_roles
    FROM 
        TopMovies m
    LEFT JOIN 
        MovieGenres g ON m.title = g.title
    LEFT JOIN 
        cast_info c ON m.title = (SELECT title FROM aka_title WHERE movie_id = c.movie_id)
    GROUP BY 
        m.title, m.production_year, g.genre
)
SELECT 
    title,
    production_year,
    STRING_AGG(DISTINCT genre, ', ') AS genres,
    unnamed_roles,
    total_roles
FROM 
    FinalResults
GROUP BY 
    title, production_year, unnamed_roles, total_roles
ORDER BY 
    production_year DESC, total_roles DESC;
