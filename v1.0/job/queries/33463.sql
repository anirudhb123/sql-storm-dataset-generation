
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(SUM(ci.nr_order), 0) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rank_within_year
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id 
    GROUP BY 
        mc.movie_id
),
RecentMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(k.keyword_count, 0) AS keyword_count,
        COALESCE(c.companies, '') AS companies,
        mh.total_cast,
        CASE 
            WHEN mh.total_cast > 5 THEN 'Large Cast'
            ELSE 'Small Cast'
        END AS cast_size_category
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        KeywordStats k ON mh.movie_id = k.movie_id
    LEFT JOIN 
        CompanyInfo c ON mh.movie_id = c.movie_id
    WHERE 
        mh.production_year >= 2000
)
SELECT 
    rm.title,
    rm.production_year,
    rm.keyword_count,
    rm.companies,
    rm.total_cast,
    rm.cast_size_category,
    COALESCE(AVG(CASE 
                    WHEN rm.production_year BETWEEN 2010 AND 2020 THEN rm.total_cast 
                    ELSE NULL 
                  END) OVER (), 0) AS avg_cast_size_2010_2020,
    COUNT(*) OVER () AS total_movies_count
FROM 
    RecentMovies rm
WHERE 
    rm.keyword_count > 2
ORDER BY 
    rm.production_year DESC, rm.keyword_count DESC;
