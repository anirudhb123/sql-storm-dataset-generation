WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT c.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info c ON a.movie_id = c.movie_id
    WHERE 
        a.production_year IS NOT NULL
    GROUP BY 
        a.title, a.production_year
),
company_info AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COALESCE(NULLIF(mc.note, ''), 'No Note'::TEXT) AS note
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
movie_keywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.actor_count,
    ci.company_name,
    ci.company_type,
    ci.note,
    mk.keywords
FROM 
    ranked_movies rm
JOIN 
    company_info ci ON rm.title = (SELECT title FROM aka_title WHERE movie_id = ci.movie_id LIMIT 1)
LEFT JOIN 
    movie_keywords mk ON rm.title = (SELECT title FROM aka_title WHERE movie_id = mk.movie_id LIMIT 1)
WHERE 
    rm.rank <= 5 AND rm.actor_count >= 10
ORDER BY 
    rm.production_year DESC, rm.actor_count DESC;
