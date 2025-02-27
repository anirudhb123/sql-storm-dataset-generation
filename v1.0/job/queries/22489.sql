WITH ranked_movies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
actor_movie_info AS (
    SELECT
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        SUM(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) AS has_note,
        MAX(CASE WHEN ci.nr_order IS NOT NULL THEN ci.nr_order ELSE 0 END) AS max_order
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ak.name, at.title, at.production_year
),
yearly_summary AS (
    SELECT 
        production_year,
        COUNT(DISTINCT movie_id) AS total_movies,
        SUM(cast_count) AS total_cast,
        AVG(cast_count) AS avg_cast_per_movie
    FROM 
        ranked_movies
    GROUP BY 
        production_year
)
SELECT 
    ym.production_year,
    ym.total_movies,
    ym.total_cast,
    ym.avg_cast_per_movie,
    am.actor_name,
    am.movie_title,
    am.max_order,
    CASE 
        WHEN am.has_note > 0 THEN 'Has Notes' 
        ELSE 'No Notes' 
    END AS note_status
FROM 
    yearly_summary ym
LEFT JOIN 
    actor_movie_info am ON ym.production_year = am.production_year
WHERE 
    ym.total_movies > 10
ORDER BY 
    ym.production_year DESC, 
    ym.avg_cast_per_movie DESC, 
    am.actor_name ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

