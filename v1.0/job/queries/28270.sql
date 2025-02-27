
WITH ranked_titles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
actor_movies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS num_appearances
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),
company_movie_details AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        complete_cast m ON mc.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    rt.keyword,
    am.actor_name,
    am.num_appearances,
    cmd.company_names,
    cmd.num_companies
FROM 
    ranked_titles rt
JOIN 
    actor_movies am ON rt.title_id = am.movie_id
JOIN 
    company_movie_details cmd ON rt.title_id = cmd.movie_id
WHERE 
    rt.keyword_rank <= 3
ORDER BY 
    rt.production_year DESC, rt.title;
