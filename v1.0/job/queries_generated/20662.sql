WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.kind_id,
        COALESCE(ct.kind, 'Unknown') AS company_kind,
        ROW_NUMBER() OVER (PARTITION BY mt.id ORDER BY mt.production_year) AS rn 
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL 

    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        COALESCE(ct.kind, 'Unknown') AS company_kind,
        rn + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title mt ON mh.production_year = mt.production_year + 1
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id 
    WHERE 
        mh.rn < 5
),

unique_keywords AS (
    SELECT DISTINCT 
        mk.movie_id,
        k.keyword 
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id 
    WHERE 
        LENGTH(k.keyword) > 5
)

SELECT 
    mh.movie_title,
    mh.production_year,
    mh.company_kind,
    COUNT(DISTINCT uk.keyword) AS unique_keyword_count,
    SUM(CASE WHEN c.note IS NULL THEN 1 ELSE 0 END) AS NULL_note_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
    MAX(CASE WHEN pi.info IS NOT NULL THEN pi.info ELSE 'No Info' END) AS person_additional_info
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    unique_keywords uk ON mh.movie_id = uk.movie_id
LEFT JOIN 
    person_info pi ON pi.person_id = c.person_id
GROUP BY 
    mh.movie_title, 
    mh.production_year, 
    mh.company_kind
HAVING 
    COUNT(DISTINCT ak.name) > 5
ORDER BY 
    mh.production_year DESC, 
    unique_keyword_count DESC;
