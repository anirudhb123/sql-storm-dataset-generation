
WITH RECURSIVE actor_movies AS (
    SELECT 
        c.person_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY c.person_id ORDER BY t.production_year DESC) AS movie_rank,
        c.movie_id
    FROM 
        cast_info c
    JOIN 
        aka_title t ON c.movie_id = t.id
    WHERE 
        c.note IS NULL 
),
company_activity AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, co.name, ct.kind
),
keyword_summary AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    a.person_id,
    a.title AS most_recent_movie,
    a.production_year,
    COALESCE(ca.company_name, 'Independent') AS production_company,
    COALESCE(ca.movie_count, 0) AS movies_by_company,
    COALESCE(ks.keywords, '') AS movie_keywords
FROM 
    actor_movies a
LEFT JOIN 
    company_activity ca ON a.movie_id = ca.movie_id
LEFT JOIN 
    keyword_summary ks ON a.movie_id = ks.movie_id
WHERE 
    a.movie_rank = 1 
ORDER BY 
    a.production_year DESC, a.person_id;
