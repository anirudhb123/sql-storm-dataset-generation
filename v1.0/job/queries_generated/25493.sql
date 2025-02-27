WITH cast_details AS (
    SELECT 
        c.id AS cast_id,
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        r.role AS role,
        COALESCE(mn.name, 'Unknown') AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        title t ON c.movie_id = t.id
    LEFT JOIN 
        movie_companies mc ON c.movie_id = mc.movie_id
    LEFT JOIN 
        company_name mn ON mc.company_id = mn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        movie_keyword mk ON c.movie_id = mk.movie_id
    LEFT JOIN 
        role_type r ON c.person_role_id = r.id
    GROUP BY 
        c.id, a.name, t.title, t.production_year, r.role, mn.name, ct.kind
),
statistics AS (
    SELECT 
        COUNT(*) AS total_casts,
        AVG(keyword_count) AS avg_keywords_per_cast,
        MAX(production_year) AS latest_movie,
        MIN(production_year) AS earliest_movie
    FROM 
        cast_details
)
SELECT 
    cd.actor_name,
    cd.movie_title,
    cd.production_year,
    cd.role,
    cd.company_name,
    cd.company_type,
    cd.keyword_count,
    s.total_casts,
    s.avg_keywords_per_cast,
    s.latest_movie,
    s.earliest_movie
FROM 
    cast_details cd, statistics s
WHERE 
    cd.production_year > 2000
ORDER BY 
    cd.production_year DESC, cd.actor_name;
