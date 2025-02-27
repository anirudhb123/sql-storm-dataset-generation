WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        t.production_year IS NOT NULL
),
movies_with_keywords AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        km.keyword
    FROM
        ranked_movies rm
    JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    JOIN 
        keyword km ON mk.keyword_id = km.id
    WHERE 
        km.keyword LIKE '%Action%' OR km.keyword LIKE '%Drama%'
),
final_result AS (
    SELECT 
        mwk.movie_id,
        mwk.title,
        mwk.production_year,
        COUNT(DISTINCT mwk.keyword) AS keyword_count
    FROM 
        movies_with_keywords mwk
    GROUP BY 
        mwk.movie_id, mwk.title, mwk.production_year
    HAVING 
        COUNT(DISTINCT mwk.keyword) > 1
)
SELECT 
    fr.movie_id,
    fr.title, 
    fr.production_year,
    CAST(
        (SELECT COUNT(*) FROM final_result) AS INTEGER
    ) AS total_movies_with_multiple_keywords
FROM 
    final_result fr
ORDER BY 
    fr.production_year DESC, 
    fr.title;