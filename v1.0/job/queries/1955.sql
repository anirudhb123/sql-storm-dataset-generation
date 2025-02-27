WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(c.name, 'Unknown') AS company_name,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS year_rank
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.production_year > 2000
    GROUP BY 
        a.id, a.title, a.production_year, c.name
),
actor_counts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT a.id) AS movie_count,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS no_note_count
    FROM 
        cast_info ci
    JOIN 
        aka_title a ON ci.movie_id = a.id
    WHERE 
        a.production_year > 2000
    GROUP BY 
        ci.person_id
),
top_actors AS (
    SELECT 
        p.name,
        ac.movie_count,
        ac.no_note_count,
        RANK() OVER (ORDER BY ac.movie_count DESC) AS actor_rank
    FROM 
        actor_counts ac
    JOIN 
        aka_name p ON ac.person_id = p.person_id
    WHERE 
        ac.movie_count > 5
)
SELECT 
    rm.title,
    rm.production_year,
    rm.company_name,
    rm.total_cast,
    ta.name AS top_actor_name,
    ta.movie_count AS top_actor_movies,
    ta.no_note_count AS top_actor_no_note
FROM 
    ranked_movies rm
LEFT JOIN 
    top_actors ta ON rm.year_rank = 1
WHERE 
    rm.total_cast > 10
ORDER BY 
    rm.production_year DESC, rm.total_cast DESC;
