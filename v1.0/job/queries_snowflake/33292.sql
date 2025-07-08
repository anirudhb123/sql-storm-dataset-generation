
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year >= 2000 

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3 
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword AS mk
    JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),

DetailedMovieInfo AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mk.keywords, 'No Keywords') AS keywords,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS role_count
    FROM 
        MovieHierarchy AS mh
    LEFT JOIN 
        complete_cast AS cc ON mh.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info AS ci ON cc.subject_id = ci.id
    LEFT JOIN 
        MovieKeywords AS mk ON mh.movie_id = mk.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year, mk.keywords
),

RankedMovies AS (
    SELECT 
        dmi.*,
        ROW_NUMBER() OVER (PARTITION BY dmi.production_year ORDER BY dmi.total_cast DESC) AS rank_within_year,
        RANK() OVER (ORDER BY dmi.total_cast DESC) AS rank_overall
    FROM 
        DetailedMovieInfo AS dmi
)

SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.keywords,
    rm.total_cast,
    rm.role_count,
    rm.rank_within_year,
    rm.rank_overall
FROM 
    RankedMovies AS rm
WHERE 
    rm.rank_within_year <= 5 
ORDER BY 
    rm.production_year DESC, 
    rm.rank_overall;
