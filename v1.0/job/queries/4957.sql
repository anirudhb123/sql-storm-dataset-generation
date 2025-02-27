WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
),
company_info AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        MAX(ct.kind) AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
movie_details AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        ci.companies,
        ci.company_type,
        (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = r.movie_id) AS keyword_count,
        COALESCE((SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = r.movie_id), 0) AS complete_cast_count
    FROM 
        ranked_movies r
    LEFT JOIN 
        company_info ci ON r.movie_id = ci.movie_id
    WHERE 
        r.actor_rank <= 5
)
SELECT 
    md.title,
    md.production_year,
    md.companies,
    md.company_type,
    md.keyword_count,
    md.complete_cast_count,
    CASE 
        WHEN md.complete_cast_count > 0 THEN 'Has complete cast'
        ELSE 'No complete cast'
    END AS cast_status
FROM 
    movie_details md
WHERE 
    md.production_year >= 2000
ORDER BY 
    md.production_year DESC, md.complete_cast_count DESC;
