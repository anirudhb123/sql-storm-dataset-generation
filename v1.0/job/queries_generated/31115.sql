WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        t.title,
        m.production_year,
        mh.movie_id AS parent_id
    FROM 
        aka_title m
    JOIN 
        title t ON m.movie_id = t.id
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(cast_info.person_role_id, 'Unknown Role') AS person_role,
    c.name AS company_name,
    COALESCE(mk.keyword, 'No Keywords') AS keyword,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    AVG(pi.info_length) AS avg_person_info_length,
    RANK() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank_by_cast_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name cn ON cn.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name c ON c.id = mc.company_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    (SELECT 
         person_id,
         LENGTH(info) AS info_length
     FROM 
         person_info 
     WHERE 
         info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
    ) pi ON pi.person_id = cn.person_id
GROUP BY 
    mh.movie_id, 
    mh.title, 
    mh.production_year, 
    person_role, 
    company_name, 
    keyword
HAVING 
    COUNT(DISTINCT ci.person_id) > 1
ORDER BY 
    mh.production_year DESC, 
    rank_by_cast_count;
