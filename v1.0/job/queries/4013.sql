
WITH movie_rankings AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title a
    JOIN 
        cast_info c ON a.id = c.movie_id
    GROUP BY 
        a.id, a.title, a.production_year
),
cast_details AS (
    SELECT 
        c.movie_id,
        ARRAY_AGG(DISTINCT n.name) AS cast_names,
        COUNT(DISTINCT n.id) AS num_cast
    FROM 
        cast_info c
    JOIN 
        aka_name n ON c.person_id = n.person_id
    GROUP BY 
        c.movie_id
),
keyword_count AS (
    SELECT 
        mk.movie_id,
        COUNT(k.id) AS num_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    mr.movie_id,
    mr.title,
    mr.production_year,
    COALESCE(cd.cast_names, ARRAY[]::TEXT[]) AS cast_names,
    COALESCE(cd.num_cast, 0) AS total_cast,
    COALESCE(kc.num_keywords, 0) AS total_keywords,
    mr.rank_by_cast
FROM 
    movie_rankings mr
LEFT JOIN 
    cast_details cd ON mr.movie_id = cd.movie_id
LEFT JOIN 
    keyword_count kc ON mr.movie_id = kc.movie_id
WHERE 
    mr.production_year = 2020 
    AND (kc.num_keywords IS NULL OR kc.num_keywords > 3)
ORDER BY 
    mr.rank_by_cast, mr.production_year DESC;
