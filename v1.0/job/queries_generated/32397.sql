WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
MovieKeywordCount AS (
    SELECT 
        m.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        m.movie_id
),
QualifiedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mkc.keyword_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieKeywordCount mkc ON mh.movie_id = mkc.movie_id
    WHERE 
        mkc.keyword_count > 5 OR mkc.keyword_count IS NULL
),
TopCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        ak.name IS NOT NULL
),
SelectedMovies AS (
    SELECT 
        qm.movie_id,
        qm.title,
        qm.production_year,
        COUNT(tc.actor_name) AS actor_count
    FROM 
        QualifiedMovies qm
    LEFT JOIN 
        TopCast tc ON qm.movie_id = tc.movie_id
    GROUP BY 
        qm.movie_id, qm.title, qm.production_year
    HAVING 
        COUNT(tc.actor_name) >= 2
)
SELECT 
    sm.movie_id,
    sm.title,
    sm.production_year,
    COALESCE(SUM(mi.info_type_id IS NOT NULL), 0) AS info_entry_count,
    STRING_AGG(DISTINCT c.name ORDER BY c.name) AS company_names
FROM 
    SelectedMovies sm
LEFT JOIN 
    movie_info mi ON sm.movie_id = mi.movie_id
LEFT JOIN 
    movie_companies mc ON sm.movie_id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
GROUP BY 
    sm.movie_id, sm.title, sm.production_year
ORDER BY 
    sm.production_year DESC, sm.title;
