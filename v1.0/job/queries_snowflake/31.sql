
WITH movie_data AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COALESCE(kt.keyword, 'No Keyword') AS keyword,
        COUNT(DISTINCT c.person_id) AS total_cast,
        ARRAY_AGG(DISTINCT a.name ORDER BY a.name) AS cast_names
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year >= 2000 
        AND t.production_year < 2020
    GROUP BY 
        t.title, t.production_year, kt.keyword
),
ranked_movies AS (
    SELECT 
        md.movie_title,
        md.production_year,
        md.keyword,
        md.total_cast,
        md.cast_names,
        RANK() OVER (PARTITION BY md.keyword ORDER BY md.total_cast DESC) AS rank_by_cast
    FROM 
        movie_data md
)
SELECT 
    r.movie_title,
    r.production_year,
    r.keyword,
    r.total_cast,
    r.cast_names
FROM 
    ranked_movies r
WHERE 
    r.rank_by_cast <= 5
ORDER BY 
    r.keyword, r.rank_by_cast;
