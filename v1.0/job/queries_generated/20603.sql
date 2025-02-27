WITH movie_performance AS (
    SELECT 
        t.title AS movie_title,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_notes,
        STRING_AGG(DISTINCT n.name, ', ') AS actor_names,
        AVG( CASE WHEN EXISTS (
            SELECT 1
            FROM movie_info mi
            WHERE mi.movie_id = t.id 
              AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')) 
              THEN CAST(mi.info AS NUMERIC) 
            ELSE NULL END) AS avg_box_office
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON c.movie_id = t.movie_id
    LEFT JOIN 
        aka_name n ON n.person_id = c.person_id
    GROUP BY 
        t.id, t.title
),
movie_keywords AS (
    SELECT 
        m.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
company_performance AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
        STRING_AGG(DISTINCT cty.kind, ', ') AS company_types,
        COUNT(DISTINCT mc.company_id) AS total_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type cty ON mc.company_type_id = cty.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mp.movie_title,
    mp.total_cast,
    CASE 
        WHEN mp.avg_box_office IS NOT NULL THEN mp.avg_box_office 
        ELSE 0 
    END AS avg_box_office,
    mp.actor_names,
    mk.all_keywords,
    cp.companies_involved,
    cp.total_companies,
    CASE 
        WHEN cp.total_companies > 10 THEN 'High'
        WHEN cp.total_companies BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low' 
    END AS company_involvement_level
FROM 
    movie_performance mp
LEFT JOIN 
    movie_keywords mk ON mp.movie_title = mk.movie_id
LEFT JOIN 
    company_performance cp ON mp.movie_title = (SELECT title FROM aka_title WHERE movie_id = cp.movie_id LIMIT 1)
WHERE 
    mp.total_cast > 0
ORDER BY 
    mp.total_cast DESC, 
    COALESCE(mp.avg_box_office, 0) DESC;
