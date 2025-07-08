
WITH RECURSIVE Ancestors AS (
    SELECT 
        c.id, 
        c.movie_id, 
        c.subject_id, 
        1 AS depth
    FROM 
        complete_cast c
        
    UNION ALL
    
    SELECT 
        cc.id, 
        cc.movie_id, 
        cc.subject_id, 
        a.depth + 1
    FROM 
        complete_cast cc
    INNER JOIN 
        Ancestors a ON cc.movie_id = a.subject_id
),
MaxRoles AS (
    SELECT 
        c.person_id, 
        COUNT(DISTINCT c.movie_id) AS role_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
RolesWithMovies AS (
    SELECT 
        a.subject_id AS movie_id, 
        LISTAGG(DISTINCT ca.name, ', ') WITHIN GROUP (ORDER BY ca.name) AS cast_names
    FROM 
        complete_cast a
    LEFT JOIN 
        cast_info ci ON a.subject_id = ci.movie_id
    LEFT JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    GROUP BY 
        a.subject_id
)
SELECT 
    t.title AS movie_title,
    t.production_year,
    r.cast_names,
    COALESCE(mc.company_count, 0) AS production_company_count,
    COALESCE(k.keyword_count, 0) AS keyword_count,
    NULLIF(mri.info, '') AS movie_info,
    ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rn
FROM 
    title t
LEFT JOIN 
    RolesWithMovies r ON t.id = r.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT company_id) AS company_count 
     FROM 
         movie_companies 
     GROUP BY 
         movie_id) mc ON t.id = mc.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         COUNT(DISTINCT keyword_id) AS keyword_count 
     FROM 
         movie_keyword 
     GROUP BY 
         movie_id) k ON t.id = k.movie_id
LEFT JOIN 
    (SELECT 
         movie_id, 
         info 
     FROM 
         movie_info 
     WHERE 
         info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis') 
         AND info IS NOT NULL) mri ON t.id = mri.movie_id
WHERE 
    t.production_year >= 2000 
    AND (t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') OR 
         t.kind_id IS NULL)
ORDER BY 
    t.production_year DESC;
