WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        0 AS level,
        ARRAY[m.id] AS path
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    WHERE 
        t.production_year >= 2000
        AND c.country_code = 'US'  -- Filters for movies produced in the US after 2000

    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.level + 1,
        mh.path || mt.id
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON mt.id = ml.linked_movie_id
    WHERE 
        mt.production_year >= 2000
        AND NOT mt.id = ANY(mh.path)  -- Ensures no cycles in recursion
),
ranked_movies AS (
    SELECT 
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS rank
    FROM 
        movie_hierarchy mh
    JOIN 
        aka_title m ON mh.movie_id = m.id
    WHERE 
        mh.level <= 3  -- Limits the depth of the hierarchy to the first 3 levels
),
names_with_roles AS (
    SELECT 
        a.name,
        c.role_id,
        COUNT(*) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.name, c.role_id
),
aggregate_roles AS (
    SELECT 
        n.name,
        STRING_AGG(DISTINCT r.role, ', ') AS roles,
        SUM(nwr.role_count) AS total_roles
    FROM 
        names_with_roles nwr
    JOIN 
        role_type r ON nwr.role_id = r.id
    GROUP BY 
        n.name
)
SELECT 
    rm.title,
    rm.production_year,
    rm.rank,
    ar.name,
    ar.roles,
    ar.total_roles
FROM 
    ranked_movies rm
LEFT JOIN 
    aggregate_roles ar ON rm.title = ANY((
        SELECT 
            STRING_AGG(DISTINCT title, ', ') 
        FROM 
            aka_title at 
        WHERE 
            at.id IN (SELECT movie_id FROM movie_info WHERE info LIKE '%actor%')
    ))
WHERE 
    ar.total_roles > 1 OR ar.total_roles IS NULL  -- Retrieves actors with more than one role or NULL roles
ORDER BY 
    rm.production_year DESC, rm.rank;
