WITH recursive movie_cast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        a.person_id,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS actor_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
),
company_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    JOIN 
        title m ON mc.movie_id = m.id
    GROUP BY 
        m.id, m.title
),
keyword_info AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
detailed_movie_info AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ci.company_names,
        ki.keywords,
        ROW_NUMBER() OVER (ORDER BY m.production_year DESC) AS movie_rank
    FROM 
        title m
    LEFT JOIN 
        company_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        keyword_info ki ON m.id = ki.movie_id
    WHERE 
        m.production_year IS NOT NULL
),
actor_stats AS (
    SELECT 
        mc.movie_id, 
        COUNT(DISTINCT mc.person_id) AS actor_count,
        MAX(mc.actor_order) AS max_actor_order
    FROM 
        movie_cast mc
    GROUP BY 
        mc.movie_id
),
final_output AS (
    SELECT 
        dmi.movie_id,
        dmi.title,
        dmi.production_year,
        COALESCE(ast.actor_count, 0) AS total_actors,
        COALESCE(dmi.keywords, 'No Keywords') AS keywords,
        CASE 
            WHEN dmi.production_year >= 2000 THEN 'Modern'
            WHEN dmi.production_year >= 1980 THEN 'Classic'
            ELSE 'Vintage'
        END AS era
    FROM 
        detailed_movie_info dmi
    LEFT JOIN 
        actor_stats ast ON dmi.movie_id = ast.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.total_actors,
    f.keywords,
    f.era,
    CASE 
        WHEN f.total_actors > 5 THEN 'Blockbuster'
        WHEN f.total_actors BETWEEN 3 AND 5 THEN 'Popular'
        ELSE 'Indie'
    END AS movie_type
FROM 
    final_output f
WHERE 
    f.production_year BETWEEN 1980 AND 2023
ORDER BY 
    f.production_year DESC, f.total_actors DESC;
