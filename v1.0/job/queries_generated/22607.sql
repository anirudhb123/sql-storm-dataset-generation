WITH RecursiveCasts AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.nr_order,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_order
    FROM 
        cast_info ci
    WHERE 
        ci.person_role_id IS NOT NULL
),
TitleDetails AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        kt.kind AS title_type,
        COALESCE(ki.info, 'No Info') AS keywords_info
    FROM 
        aka_title at
    LEFT JOIN 
        kind_type kt ON at.kind_id = kt.id
    LEFT JOIN (
        SELECT 
            mk.movie_id, 
            STRING_AGG(k.keyword, ', ') AS info 
        FROM 
            movie_keyword mk
        JOIN 
            keyword k ON mk.keyword_id = k.id
        GROUP BY 
            mk.movie_id
    ) ki ON at.movie_id = ki.movie_id
)
SELECT 
    t.title,
    t.production_year,
    COALESCE(n.name, 'Unknown Actor') AS actor_name,
    rc.role_order,
    t.title_type,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mt.info IS NOT NULL THEN 1 ELSE 0 END) AS info_present_count,
    MAX(CASE WHEN mt.note IS NOT NULL THEN mt.note ELSE 'No Notes' END) AS latest_note,
    STRING_AGG(DISTINCT t2.title, '; ') AS linked_titles
FROM 
    TitleDetails t
LEFT JOIN 
    RecursiveCasts rc ON t.title_id = rc.movie_id
LEFT JOIN 
    name n ON rc.person_id = n.id
LEFT JOIN 
    movie_companies mc ON t.title_id = mc.movie_id
LEFT JOIN 
    movie_info mt ON t.title_id = mt.movie_id
LEFT JOIN 
    movie_link ml ON t.title_id = ml.movie_id
LEFT JOIN 
    aka_title t2 ON ml.linked_movie_id = t2.id
WHERE 
    t.production_year = (SELECT MAX(production_year) FROM aka_title) 
    AND t.production_year IS NOT NULL
GROUP BY 
    t.title, t.production_year, n.name, rc.role_order, t.title_type
HAVING 
    COUNT(n.id) > 0
ORDER BY 
    t.production_year DESC, 
    t.title;
