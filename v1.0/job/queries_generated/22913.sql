WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieKeywords AS (
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
PersonRoles AS (
    SELECT 
        p.id AS person_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(distinct ci.movie_id) AS role_count
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        p.id, a.name, rt.role
),
ExtendedInfo AS (
    SELECT 
        t.id AS movie_id,
        COALESCE(k.keywords, 'No Keywords') AS keywords,
        COALESCE(MAX(IF(pi.info_type_id = 1, pi.info, NULL)), 'No Info') AS director_info,
        COALESCE(MAX(IF(pi.info_type_id = 2, pi.info, NULL)), 'No Info') AS writer_info
    FROM 
        aka_title t
    LEFT JOIN 
        MovieKeywords k ON t.id = k.movie_id
    LEFT JOIN 
        movie_info mi ON t.id = mi.movie_id
    LEFT JOIN 
        person_info pi ON pi.person_id = mi.info_type_id
    GROUP BY 
        t.id
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.production_year,
    RM.cast_count,
    EI.keywords,
    EI.director_info,
    EI.writer_info,
    RO.role_name,
    RO.role_count
FROM 
    RankedMovies RM
LEFT JOIN 
    ExtendedInfo EI ON RM.movie_id = EI.movie_id
LEFT JOIN 
    PersonRoles RO ON RM.cast_count = RO.role_count
WHERE 
    RM.rank <= 5 
AND 
    RM.production_year IS NOT NULL 
ORDER BY 
    RM.production_year DESC, RM.cast_count DESC;

This SQL query selects the top 5 movies by cast count per production year, aggregating relevant information such as keywords, director, and writer info, alongside actors and their respective roles. It makes use of CTEs for organization and clarity, employs window functions for ranking, and includes various joins and aggregations, while addressing NULLs with `COALESCE`. This query offers a comprehensive view of the selected movies, showcasing its flexibility and efficacy for performance benchmarking within the provided schema.
