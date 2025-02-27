WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedCast AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY cic.nr_order) AS actor_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN
        role_type cic ON ci.role_id = cic.id
),
AggregateKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieDetails AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        rc.actor_name,
        rk.keywords,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        RankedCast rc ON mh.movie_id = rc.movie_id
    LEFT JOIN 
        movie_companies mc ON mh.movie_id = mc.movie_id
    LEFT JOIN 
        AggregateKeywords rk ON mh.movie_id = rk.movie_id
    GROUP BY 
        mh.movie_id, mh.movie_title, mh.production_year, rc.actor_name, rk.keywords
)
SELECT 
    md.movie_title,
    md.production_year,
    md.actor_name,
    md.keywords,
    md.company_count,
    CASE 
        WHEN md.keywords IS NULL THEN 'No Keywords'
        ELSE 'Keywords Available'
    END AS keyword_status
FROM 
    MovieDetails md
WHERE 
    md.company_count > 1 
    AND md.production_year BETWEEN 2000 AND 2023
ORDER BY 
    md.production_year DESC, md.actor_name;
