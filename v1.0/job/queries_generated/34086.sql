WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        1 AS level
    FROM 
        title
    WHERE 
        title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        tt.id AS movie_id,
        tt.title,
        tt.production_year,
        mh.level + 1
    FROM 
        title tt
    JOIN 
        movie_link ml ON tt.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovie AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.level ORDER BY mh.production_year ASC) AS year_rank
    FROM 
        MovieHierarchy mh
),
CastInfoWithRole AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        rp.role,
        ak.name AS actor_name,
        ci.nr_order
    FROM 
        cast_info ci
    JOIN 
        role_type rp ON ci.role_id = rp.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
),
CompanyCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.level,
    cwr.actor_name,
    cwr.role,
    cc.company_count,
    COALESCE(rc.production_year, 'No Linked Movies') AS linked_movie_year
FROM 
    RankedMovie rm
LEFT JOIN 
    CastInfoWithRole cwr ON rm.movie_id = cwr.movie_id
LEFT JOIN 
    CompanyCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    (SELECT 
         ml.movie_id,
         ml.linked_movie_id,
         t.production_year 
     FROM 
         movie_link ml 
     JOIN 
         title t ON ml.linked_movie_id = t.id 
     WHERE 
         ml.link_type_id = (SELECT id FROM link_type WHERE link = 'remake')) rc ON rm.movie_id = rc.movie_id
WHERE 
    cwr.nr_order IS NULL OR cwr.nr_order < 5
ORDER BY 
    rm.production_year DESC, 
    rm.title, 
    cwr.nr_order;
