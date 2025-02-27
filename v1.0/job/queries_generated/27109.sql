WITH movie_years AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        count(c.person_id) AS cast_count
    FROM 
        title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        t.id, t.title, t.production_year
), 
popular_names AS (
    SELECT 
        a.person_id, 
        a.name, 
        count(ci.movie_id) AS movie_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    GROUP BY 
        a.person_id, a.name
    HAVING 
        count(ci.movie_id) > 5
), 
keyword_summary AS (
    SELECT 
        mk.movie_id,
        array_agg(k.keyword) AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    my.title,
    my.production_year,
    my.cast_count,
    pn.name AS popular_actor,
    ks.keywords_list
FROM 
    movie_years my
JOIN 
    popular_names pn ON my.cast_count = (
        SELECT MAX(cast_count) 
        FROM movie_years 
        WHERE production_year = my.production_year
    )
LEFT JOIN 
    keyword_summary ks ON my.title_id = ks.movie_id
ORDER BY 
    my.production_year DESC, 
    my.cast_count DESC;
