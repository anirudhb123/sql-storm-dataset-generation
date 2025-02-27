WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        RANK() OVER (PARTITION BY m.production_year ORDER BY LENGTH(m.title) DESC) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
company_information AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mc.id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
actor_information AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        COUNT(ci.person_id) AS num_actors,
        SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ci.movie_id IS NOT NULL
    GROUP BY 
        ci.movie_id, ak.name
),
final_results AS (
    SELECT 
        rm.title,
        rm.production_year,
        ci.company_name,
        ci.company_type,
        ai.actor_name,
        RANK() OVER (PARTITION BY rm.production_year ORDER BY ai.num_actors DESC) AS actor_rank,
        ai.notes_count
    FROM 
        ranked_movies rm
    LEFT JOIN 
        company_information ci ON rm.movie_id = ci.movie_id
    LEFT JOIN 
        actor_information ai ON rm.movie_id = ai.movie_id
    WHERE 
        (rm.title_rank = 1 OR (ci.num_companies > 2 AND ai.notes_count > 0))
)
SELECT 
    title,
    production_year,
    COALESCE(company_name, 'Independent') AS company_name,
    COALESCE(company_type, 'N/A') AS company_type,
    actor_name,
    actor_rank,
    notes_count
FROM 
    final_results
ORDER BY 
    production_year DESC, actor_rank ASC, title;
