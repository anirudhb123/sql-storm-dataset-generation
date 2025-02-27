WITH movie_info_enriched AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mk.keyword,
        ci.note AS cast_note,
        COALESCE(cn.country_code, 'Unknown') AS company_country,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        aka_title m
    JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    JOIN 
        complete_cast cc ON m.id = cc.movie_id
    JOIN 
        cast_info c ON cc.subject_id = c.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        m.production_year > 2000
    GROUP BY 
        m.id, m.title, m.production_year, mk.keyword, ci.note, cn.country_code
),
info_summary AS (
    SELECT 
        movie_id,
        STRING_AGG(info, '; ') AS movie_info_summary
    FROM 
        movie_info
    GROUP BY 
        movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.keyword,
    m.cast_note,
    m.company_country,
    m.total_cast_members,
    m.actor_names,
    i.movie_info_summary
FROM 
    movie_info_enriched m
LEFT JOIN 
    info_summary i ON m.movie_id = i.movie_id
ORDER BY 
    m.production_year DESC, 
    m.title;
