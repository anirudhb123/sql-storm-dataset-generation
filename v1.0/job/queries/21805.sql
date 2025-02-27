
WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        MAX(CASE WHEN k.keyword IS NOT NULL THEN k.keyword ELSE 'No Keywords' END) AS keywords,
        RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id, m.title, m.production_year
),
movie_companies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
combined_results AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_count,
        md.actor_names,
        md.keywords,
        mc.company_names,
        mc.company_types,
        COALESCE(md.rank_by_cast, 0) AS rank_by_cast
    FROM 
        movie_details md
    FULL OUTER JOIN 
        movie_companies mc ON md.movie_id = mc.movie_id
)
SELECT 
    cr.movie_id,
    cr.title,
    cr.production_year,
    cr.cast_count,
    cr.actor_names,
    cr.keywords,
    cr.company_names,
    cr.company_types,
    cr.rank_by_cast,
    CASE 
        WHEN cr.rank_by_cast > 0 THEN 'Ranked Movie'
        ELSE 'Unranked Movie'
    END AS movie_status
FROM 
    combined_results cr
WHERE 
    cr.production_year IS NOT NULL
    AND (cr.cast_count IS NULL OR cr.cast_count > 5)
ORDER BY 
    cr.production_year DESC, cr.rank_by_cast
LIMIT 50;
