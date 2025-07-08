WITH most_common_names AS (
    SELECT 
        a.name, 
        COUNT(c.person_id) AS name_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name
    ORDER BY 
        name_count DESC
    LIMIT 10
),
recent_movies AS (
    SELECT 
        t.title, 
        t.production_year, 
        COUNT(c.person_id) AS cast_count
    FROM 
        title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    WHERE 
        t.production_year > 2015
    GROUP BY 
        t.title, t.production_year
    ORDER BY 
        t.production_year DESC
    LIMIT 5
),
most_frequent_keywords AS (
    SELECT 
        k.keyword, 
        COUNT(m.movie_id) AS keyword_count
    FROM 
        keyword k
    JOIN 
        movie_keyword m ON k.id = m.keyword_id
    GROUP BY 
        k.keyword
    ORDER BY 
        keyword_count DESC
    LIMIT 5
)
SELECT 
    mn.name AS most_common_name,
    rm.title AS recent_movie_title,
    rm.production_year AS recent_movie_year,
    fk.keyword AS frequent_keyword,
    mn.name_count,
    rm.cast_count,
    fk.keyword_count
FROM 
    most_common_names mn
CROSS JOIN 
    recent_movies rm
CROSS JOIN 
    most_frequent_keywords fk;
