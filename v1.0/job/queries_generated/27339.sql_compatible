
WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        aka_title t
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year
), 
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
movie_info_summary AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(CONCAT(i.info, ' (', mi.note, ')'), '; ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        info_type i ON mi.info_type_id = i.id
    GROUP BY 
        mi.movie_id
)

SELECT 
    rm.title,
    rm.production_year,
    rm.num_cast_members,
    rm.cast_names,
    mk.keywords,
    mis.info_details
FROM 
    ranked_movies rm
LEFT JOIN 
    movie_keywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    movie_info_summary mis ON rm.movie_id = mis.movie_id
WHERE 
    rm.num_cast_members > 5
ORDER BY 
    rm.production_year DESC, 
    rm.num_cast_members DESC;
