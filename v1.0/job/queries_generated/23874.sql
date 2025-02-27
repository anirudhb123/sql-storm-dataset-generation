WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    GROUP BY 
        t.id, t.title, t.production_year
),
RatedMovies AS (
    SELECT 
        tm.title,
        tm.production_year,
        AVG(CASE 
                WHEN pi.info_type_id = 1 THEN CAST(pi.info AS NUMERIC)
                ELSE NULL 
            END) AS average_rating
    FROM 
        RankedMovies tm
    LEFT JOIN 
        movie_info mi ON tm.title_id = mi.movie_id
    LEFT JOIN 
        person_info pi ON mi.info_type_id = pi.info_type_id
    GROUP BY 
        tm.title, tm.production_year
),
HighlyRated AS (
    SELECT 
        title, 
        production_year
    FROM 
        RatedMovies 
    WHERE 
        average_rating IS NOT NULL AND 
        average_rating > 8
),
ConnectedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        ml.linked_movie_id,
        t1.title AS linked_title
    FROM 
        title m
    LEFT JOIN 
        movie_link ml ON m.id = ml.movie_id
    LEFT JOIN 
        title t1 ON ml.linked_movie_id = t1.id
)
SELECT 
    hr.title AS highly_rated_title,
    hr.production_year,
    COUNT(DISTINCT cm.linked_movie_id) AS number_of_connected_movies,
    STRING_AGG(DISTINCT cm.linked_title, ', ') AS connected_movie_titles
FROM 
    HighlyRated hr
LEFT JOIN 
    ConnectedMovies cm ON hr.title = cm.title
GROUP BY 
    hr.title, hr.production_year
HAVING 
    COUNT(DISTINCT cm.linked_movie_id) > 0
ORDER BY 
    hr.production_year DESC, 
    number_of_connected_movies DESC;
