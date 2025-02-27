WITH RecursiveCTE AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_order,
        AVG(CASE 
            WHEN ti.production_year IS NOT NULL THEN ti.production_year 
            ELSE 0 END) AS avg_production_year
    FROM 
        cast_info ca
    LEFT JOIN 
        title ti ON ca.movie_id = ti.id
    WHERE 
        ca.nr_order IS NOT NULL
    GROUP BY 
        ca.person_id, ca.movie_id
),
ExtendedInfo AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        r.role_order,
        c.movie_id,
        ci.note AS cast_note,
        COALESCE(ca.role_id, -1) AS role_identifier
    FROM 
        aka_name a
    JOIN 
        RecursiveCTE r ON a.person_id = r.person_id
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id AND r.person_id = ci.person_id
    LEFT JOIN 
        comp_cast_type ca ON ci.person_role_id = ca.id
)
SELECT 
    ei.aka_id, 
    ei.aka_name, 
    ei.role_order, 
    ei.movie_id,
    (SELECT 
        COUNT(*) 
     FROM 
        movie_keyword mk
     WHERE 
        mk.movie_id = ei.movie_id) AS keyword_count,
    STRING_AGG(DISTINCT k.keyword, ', ') FILTER (WHERE k.keyword IS NOT NULL) AS keywords,
    CASE 
        WHEN ei.role_identifier IS NULL THEN 'Unknown' 
        ELSE ct.kind 
    END AS company_type
FROM 
    ExtendedInfo ei
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ei.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = ei.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
WHERE 
    ei.role_order > 1 
    AND (ei.cast_note IS NULL OR ei.cast_note NOT LIKE '%extra%')
GROUP BY 
    ei.aka_id, ei.aka_name, ei.role_order, ei.movie_id, ei.role_identifier, ct.kind
HAVING 
    COALESCE(EAVG(ei.role_order), 0) > 1
ORDER BY 
    ei.role_order DESC, ei.aka_name;

-- This query uses window functions for ranking,
-- recursive common table expressions for calculating avg production years,
-- outer joins to gather additional info, filtering with complicated predicates,
-- and also aggregates with NULL logic and string manipulation.
