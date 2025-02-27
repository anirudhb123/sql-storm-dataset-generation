WITH movie_data AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS director_name,
        GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id AND cn.country_code = 'USA'
    JOIN 
        complete_cast cc ON t.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    JOIN 
        aka_name a ON c.person_id = a.person_id AND a.name_pcode_cf IS NOT NULL
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
    GROUP BY 
        t.id, t.title, t.production_year, a.name
),
rating_data AS (
    SELECT 
        movie_id,
        AVG(rating) AS average_rating
    FROM 
        (
            SELECT movie_id, rating FROM movie_info WHERE info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
        ) r
    GROUP BY movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.director_name,
    md.keywords,
    md.cast_count,
    COALESCE(rd.average_rating, 0) AS average_rating
FROM 
    movie_data md
LEFT JOIN 
    rating_data rd ON md.movie_id = rd.movie_id
ORDER BY 
    md.production_year DESC,
    md.title ASC;
