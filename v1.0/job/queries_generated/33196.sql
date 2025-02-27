WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL AND 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS rank
    FROM 
        MovieHierarchy mh
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT kc.keyword) AS keyword_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.movie_id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN 
        keyword kc ON kc.id = mk.keyword_id
    GROUP BY 
        tm.movie_id, tm.title
),
FinalOutput AS (
    SELECT 
        md.title,
        md.production_year,
        COALESCE(md.companies, 'No Companies') AS companies,
        md.keyword_count,
        CASE 
            WHEN md.keyword_count > 10 THEN 'Popular'
            WHEN md.keyword_count BETWEEN 6 AND 10 THEN 'Moderate'
            ELSE 'Less Known'
        END AS popularity
    FROM 
        MovieDetails md
)
SELECT 
    f.title,
    f.production_year,
    f.companies,
    f.keyword_count,
    f.popularity
FROM 
    FinalOutput f
WHERE 
    f.keyword_count IS NOT NULL
ORDER BY 
    f.production_year DESC, f.popularity;
