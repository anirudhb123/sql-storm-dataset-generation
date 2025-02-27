WITH MovieRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_type,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
KeywordMatch AS (
    SELECT 
        m.movie_id, 
        COUNT(k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        title m ON mk.movie_id = m.id
    GROUP BY 
        m.movie_id
),
ProductionInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_list
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    WHERE 
        it.info ILIKE '%production%'
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title,
    COALESCE(mr.actor_name, 'Unknown Actor') AS lead_actor,
    COALESCE(p.info_list, 'No Production Info') AS production_info,
    km.keyword_count,
    t.production_year,
    CASE 
        WHEN t.production_year IS NULL THEN 'Year Not Available'
        ELSE 'Released in ' || t.production_year::text
    END AS production_status
FROM 
    title t
LEFT JOIN 
    MovieRoles mr ON t.id = mr.movie_id AND mr.role_order = 1
LEFT JOIN 
    KeywordMatch km ON t.id = km.movie_id
LEFT JOIN 
    ProductionInfo p ON t.id = p.movie_id
WHERE 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series'))
  AND 
    (t.production_year >= 2000 OR t.production_year IS NULL)
ORDER BY 
    t.production_year DESC NULLS LAST, 
    t.title;
