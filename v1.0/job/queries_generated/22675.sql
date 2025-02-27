WITH ranked_movies AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS title_rank,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY at.id) AS cast_count
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
),
filtered_movies AS (
    SELECT 
        rm.title_id,
        rm.title,
        rm.production_year,
        rm.title_rank,
        rm.cast_count
    FROM 
        ranked_movies rm
    WHERE 
        rm.cast_count > 3
),
movies_with_keywords AS (
    SELECT 
        f.title_id,
        f.title,
        f.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords
    FROM 
        filtered_movies f
    LEFT JOIN 
        movie_keyword mk ON f.title_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        f.title_id, f.title, f.production_year
),
cast_info_summary AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT ak.name) AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
)

SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(k.keywords, '{}') AS keywords,
    COALESCE(c.cast_names, '{}') AS cast_members
FROM 
    movies_with_keywords m
LEFT JOIN 
    cast_info_summary c ON m.title_id = c.movie_id
LEFT JOIN 
    (SELECT
        k.title_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
     FROM 
        filtered_movies f
     JOIN 
        movie_keyword mk ON f.title_id = mk.movie_id
     JOIN 
        keyword k ON mk.keyword_id = k.id
     GROUP BY 
        k.title_id) k ON m.title_id = k.title_id
WHERE 
    m.title_rank < 10
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
