WITH recursive movie_data AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS title,
        mt.production_year,
        coalesce(mci.note, 'No Note') AS company_note,
        ARRAY_AGG(DISTINCT ak.name) AS actors,
        COUNT(DISTINCT ak.person_id) AS actor_count,
        COUNT(DISTINCT mk.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS row_num
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mci ON mt.id = mci.movie_id
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year, mci.note
), filtered_movies AS (
    SELECT 
        *,
        CASE 
            WHEN actor_count > 10 THEN 'Many Actors' 
            WHEN actor_count IS NULL THEN 'No Actors' 
            ELSE 'Few Actors' 
        END AS actor_description
    FROM 
        movie_data
    WHERE 
        production_year BETWEEN 2000 AND 2023
), high_keyword_movies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        actor_description,
        keyword_count
    FROM 
        filtered_movies
    WHERE 
        keyword_count > 5 AND actor_description = 'Many Actors'
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.actor_description,
    COALESCE(NULLIF(f.company_note, 'No Note'), 'Company Info Unavailable') AS final_company_note,
    RANK() OVER (ORDER BY f.production_year DESC) AS year_rank
FROM 
    filtered_movies f
LEFT JOIN 
    high_keyword_movies hkm ON f.movie_id = hkm.movie_id
WHERE 
    f.actor_description <> 'No Actors' OR hkm.movie_id IS NOT NULL
ORDER BY 
    f.production_year DESC, 
    f.row_num;
