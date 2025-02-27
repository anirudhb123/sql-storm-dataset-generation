WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        c.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieCTE c ON m.episode_of_id = c.movie_id
),
MovieDetails AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT ko.keyword) AS keyword_count
    FROM 
        MovieCTE m
    LEFT JOIN 
        complete_cast cc ON m.movie_id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = m.movie_id
    LEFT JOIN 
        aka_name c ON c.person_id = ci.person_id
    LEFT JOIN 
        movie_keyword ko ON m.movie_id = ko.movie_id
    GROUP BY 
        m.movie_id
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT co.name, ', ') AS companies,
        COUNT(DISTINCT ct.kind) AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    md.title AS movie_title,
    md.production_year,
    md.cast_names,
    md.keyword_count,
    co.companies,
    co.company_types
FROM 
    MovieDetails md
LEFT JOIN 
    CompanyDetails co ON md.movie_id = co.movie_id
WHERE 
    md.keyword_count > 5
ORDER BY 
    md.production_year DESC,
    md.keyword_count DESC;

This SQL query includes the following features:

1. **CTEs**: Recursive CTE for fetching movies and their episodes.
2. **LEFT JOINs**: Joining multiple tables to fetch cast names and associated companies.
3. **STRING_AGG**: To concatenate cast names and company names into a single string.
4. **GROUP BY**: To aggregate data for movies, cast, and companies.
5. **COUNT**: To count the number of unique keywords and company types.
6. **WHERE Clause**: To filter movies with more than five keywords.
7. **ORDER BY**: To sort the results by production year and then keyword count. 

This query thus aims to provide comprehensive data on movies produced after 2000, the cast involved, keywords associated with them, and the production companies involved.
