WITH ranked_movies AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT c.person_id) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        COALESCE(SUM(CASE WHEN c.nr_order < 4 THEN 1 ELSE 0 END), 0) AS lead_cast_count
    FROM 
        aka_title mt
    JOIN 
        movie_info mi ON mt.movie_id = mi.movie_id
    JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    JOIN 
        keyword kw ON mk.keyword_id = kw.id
    JOIN 
        cast_info c ON mt.movie_id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        mt.production_year > 2000
        AND mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Genre')
        AND ak.name IS NOT NULL
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
high_cast_movies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_names,
        keywords,
        lead_cast_count
    FROM 
        ranked_movies
    WHERE 
        total_cast > 5 AND lead_cast_count > 1
)
SELECT 
    hcm.movie_title,
    hcm.production_year,
    hcm.total_cast,
    hcm.cast_names,
    hcm.keywords,
    CASE 
        WHEN hcm.lead_cast_count > 2 THEN 'Star-Studded'
        ELSE 'Ensemble'
    END AS cast_type
FROM 
    high_cast_movies hcm
ORDER BY 
    hcm.production_year DESC, 
    hcm.total_cast DESC
LIMIT 10;
