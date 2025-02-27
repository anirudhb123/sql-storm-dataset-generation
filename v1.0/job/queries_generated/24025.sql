WITH RecursiveMovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        rm.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        RecursiveMovieHierarchy rm ON ml.movie_id = rm.movie_id
    WHERE 
        a.production_year IS NOT NULL
),
TitleRoles AS (
    SELECT 
        c.movie_id,
        r.role,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id, r.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(tr.role, 'Unknown Role') AS role,
    tr.role_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN tr.role IS NOT NULL THEN 'Has Role'
        ELSE 'No Role'
    END AS role_availability,
    CASE 
        WHEN mk.keywords IS NULL THEN NULL
        ELSE LENGTH(mk.keywords) - LENGTH(REPLACE(mk.keywords, ',', '')) + 1
    END AS keyword_count,
    (SELECT COUNT(DISTINCT person_id) FROM cast_info ci WHERE ci.movie_id = rm.movie_id) AS unique_cast_members,
    ARRAY_AGG(DISTINCT cm.name) FILTER (WHERE cm.name IS NOT NULL) AS production_companies
FROM 
    RecursiveMovieHierarchy rm
LEFT JOIN 
    TitleRoles tr ON rm.movie_id = tr.movie_id
LEFT JOIN 
    MovieKeywords mk ON rm.movie_id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = rm.movie_id
LEFT JOIN 
    company_name cm ON mc.company_id = cm.id
WHERE 
    rm.depth <= 2
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, tr.role, tr.role_count, mk.keywords
ORDER BY 
    rm.production_year DESC, rm.title ASC;
