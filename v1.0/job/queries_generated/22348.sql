WITH movie_summary AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT( DISTINCT ca.person_id ) AS total_cast,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        MAX(CASE WHEN ci.kind_id IS NOT NULL THEN ci.kind_id END) AS main_character_type,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        t.title, t.production_year
), ranked_movies AS (
    SELECT 
        ms.movie_title,
        ms.production_year,
        ms.total_cast,
        ms.actor_names,
        ms.main_character_type,
        ms.null_notes_count,
        ROW_NUMBER() OVER (PARTITION BY ms.production_year ORDER BY ms.total_cast DESC) AS rank_within_year
    FROM 
        movie_summary ms
), recent_movies AS (
    SELECT 
        DISTINCT movie_title
    FROM 
        ranked_movies 
    WHERE 
        production_year = (SELECT MAX(production_year) FROM ranked_movies)
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.total_cast,
    rm.actor_names,
    CASE 
        WHEN rm.main_character_type IS NULL THEN 'Unknown' 
        ELSE rm.main_character_type 
    END AS character_type,
    rm.null_notes_count,
    COALESCE((SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = (SELECT at.id FROM aka_title at WHERE at.title = rm.movie_title LIMIT 1)), 0) AS keyword_count,
    CASE 
        WHEN rm.total_cast > 20 THEN 'Ensemble Cast'
        WHEN rm.total_cast BETWEEN 10 AND 20 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    ranked_movies rm
WHERE 
    rm.rank_within_year <= 5 
    OR rm.movie_title IN (SELECT movie_title FROM recent_movies)
ORDER BY 
    rm.production_year DESC, 
    rm.total_cast DESC;

