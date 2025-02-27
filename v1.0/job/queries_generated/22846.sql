WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
        AND mt.title IS NOT NULL
), 
MovieCast AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT ci.person_id) AS cast_member_count,
        SUM(CASE WHEN ci.nr_order < 5 THEN 1 ELSE 0 END) AS top_five_roles,
        STRING_AGG(DISTINCT a.name, ', ') AS all_cast_names
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.subject_id = ci.id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        mc.movie_id
), 
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords_list
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, '; ') AS companies_list 
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), 
MoviesWithDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(mr.cast_member_count, 0) AS cast_member_count,
        COALESCE(mk.keywords_list, 'None') AS keywords_list,
        COALESCE(mc.companies_list, 'No Companies') AS companies_list,
        CASE 
            WHEN rm.production_year >= 2000 AND mr.cast_member_count > 10 THEN 'Modern Blockbuster' 
            WHEN rm.production_year < 2000 AND mr.cast_member_count <= 3 THEN 'Niche Film' 
            ELSE 'Mid-level Production' 
        END AS movie_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieCast mr ON rm.movie_id = mr.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)

SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    m.cast_member_count,
    m.keywords_list,
    m.companies_list,
    m.movie_category,
    ROW_NUMBER() OVER (PARTITION BY m.movie_category ORDER BY m.production_year DESC) AS category_rank,
    (SELECT COUNT(*) FROM MovieCast WHERE cast_member_count > 1) AS total_collaborative_films,
    (SELECT COUNT(DISTINCT company_id) FROM movie_companies WHERE movie_id IN (SELECT movie_id FROM MovieCast WHERE cast_member_count > 5)) AS total_companies_for_collabs
FROM 
    MoviesWithDetails m
WHERE 
    m.title ILIKE '%adventure%' 
    AND m.keywords_list NOT LIKE '%horror%' 
    AND m.production_year IS NOT NULL 
ORDER BY 
    m.production_year DESC, 
    m.movie_category;
