WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
),
cast_statistics AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        COUNT(DISTINCT ci.role_id) FILTER (WHERE ci.note IS NOT NULL) AS speaking_roles
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
yearly_production AS (
    SELECT 
        production_year,
        COUNT(*) AS movies_count
    FROM 
        aka_title
    GROUP BY 
        production_year
    HAVING 
        COUNT(*) > 10
),
movies_with_info AS (
    SELECT 
        title.id AS title_id,
        title.title AS movie_title,
        ct.kind AS company_type,
        yi.production_year,
        cs.total_cast,
        cs.speaking_roles,
        ROW_NUMBER() OVER (PARTITION BY yi.production_year ORDER BY cs.total_cast DESC) AS rank_by_cast
    FROM 
        aka_title title
    LEFT JOIN 
        movie_companies mc ON title.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN 
        cast_statistics cs ON title.id = cs.movie_id
    LEFT JOIN 
        yearly_production yi ON title.production_year = yi.production_year
)
SELECT 
    mwi.movie_title,
    mwi.company_type,
    mwi.production_year,
    mwi.total_cast,
    COALESCE(mwi.speaking_roles, 0) AS speaking_roles,
    mh.depth
FROM 
    movies_with_info mwi
LEFT JOIN 
    movie_hierarchy mh ON mwi.title_id = mh.movie_id
WHERE 
    mwi.production_year IS NOT NULL
    AND mwi.rank_by_cast <= 5
ORDER BY 
    mwi.production_year DESC, 
    mwi.total_cast DESC;

