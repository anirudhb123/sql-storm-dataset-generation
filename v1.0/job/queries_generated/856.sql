WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
recent_movies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        ranked_movies
    WHERE 
        actor_rank <= 10
),
movie_details AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(info.info, 'No additional information') AS additional_info,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        recent_movies rm
    LEFT JOIN 
        movie_info info ON rm.movie_id = info.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = rm.movie_id
    GROUP BY 
        rm.title, rm.production_year
)
SELECT 
    md.title,
    md.production_year,
    md.additional_info,
    md.keyword_count,
    md.keywords,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = md.movie_id AND mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')) AS distributor_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = md.movie_id) IS NULL THEN 'No companies associated'
        ELSE 'Companies found'
    END AS company_status
FROM 
    movie_details md
ORDER BY 
    md.production_year DESC, md.keyword_count DESC;
