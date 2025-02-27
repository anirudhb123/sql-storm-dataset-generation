WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        NULL::integer AS parent_id, 
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL  -- Top-level movies
    UNION ALL
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        t.kind_id,
        h.movie_id AS parent_id, 
        h.level + 1
    FROM 
        aka_title t
    JOIN 
        MovieHierarchy h ON t.episode_of_id = h.movie_id  -- Join for episodes
)
, MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.kind_id,
        COALESCE(c.role_id, 'Not Available') AS role_id,
        COUNT(DISTINCT DISTINCT c.person_id) OVER (PARTITION BY mh.movie_id) AS total_cast,
        (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = mh.movie_id AND mc.company_type_id IS NOT NULL) AS total_companies,
        ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON c.movie_id = mh.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    COALESCE(k.keyword, 'No Keywords') AS keyword,
    md.total_cast,
    md.total_companies
FROM 
    MovieDetails md
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = md.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    md.production_year >= (
        SELECT AVG(production_year) FROM aka_title
    ) AND
    (md.kind_id IS NOT NULL OR md.role_id NOT IN (SELECT id FROM role_type WHERE role LIKE '%supporting%'))
ORDER BY 
    md.total_cast DESC,
    md.production_year DESC
LIMIT 10;
