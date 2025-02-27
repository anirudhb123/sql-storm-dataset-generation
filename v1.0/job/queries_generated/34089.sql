WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        NULL::integer AS parent_id
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL 
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.movie_id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS rank_by_title
    FROM 
        MovieHierarchy mh
),
CompanySummary AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(cs.company_count, 0) AS companies_involved,
        COUNT(DISTINCT ki.keyword) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CompanySummary cs ON rm.movie_id = cs.movie_id
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, cs.company_count
)
SELECT 
    md.title,
    md.production_year,
    md.companies_involved,
    md.keyword_count,
    ROW_NUMBER() OVER (ORDER BY md.production_year DESC, md.title) AS overall_rank
FROM 
    MovieDetails md
WHERE 
    md.production_year > 2000
ORDER BY 
    md.production_year DESC, md.title;
