WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.note DESC) AS rank_within_year,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies_in_year,
        COALESCE(b.note, 'No Notes') AS movie_notes,
        COALESCE(c.name, 'Unknown') AS director_name
    FROM 
        aka_title a
    LEFT JOIN 
        movie_info b ON a.id = b.movie_id AND b.info_type_id = (SELECT id FROM info_type WHERE info = 'note')
    LEFT JOIN 
        cast_info c ON a.id = c.movie_id AND c.person_role_id = (SELECT id FROM role_type WHERE role = 'Director')
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN rank_within_year = 1 THEN 'Best Film of the Year'
            WHEN rank_within_year <= 5 THEN 'Top 5 Films of the Year'
            ELSE 'Notable Film'
        END AS film_category
    FROM 
        RankedMovies
    WHERE 
        total_movies_in_year > 10
        OR movie_notes LIKE '%Award%'
        OR director_name IS NOT NULL
),
UnnotedMovies AS (
    SELECT 
        title,
        production_year,
        'No Notations' AS category
    FROM 
        aka_title t
    WHERE 
        t.id NOT IN (SELECT movie_id FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'note'))
),
FinalMovies AS (
    SELECT 
        title,
        production_year,
        film_category
    FROM 
        FilteredMovies
    UNION ALL 
    SELECT 
        title,
        production_year,
        category
    FROM 
        UnnotedMovies
)
SELECT 
    f.title,
    f.production_year,
    f.film_category,
    CASE 
        WHEN f.production_year < 2000 THEN 'Classic'
        WHEN f.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS era_category,
    COUNT(*) OVER (PARTITION BY f.film_category) AS total_in_category
FROM 
    FinalMovies f
WHERE 
    f.production_year >= 1980
ORDER BY 
    f.production_year DESC, 
    f.title;
