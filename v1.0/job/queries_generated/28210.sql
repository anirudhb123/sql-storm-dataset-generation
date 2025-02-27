WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        AVG(CASE WHEN LENGTH(mt.title) > 10 THEN LENGTH(mt.title) ELSE NULL END) AS avg_title_length
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
CastRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast, 
        ARRAY_AGG(DISTINCT rt.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
KeywordInfo AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.company_count,
    rm.avg_title_length,
    COALESCE(cr.total_cast, 0) AS total_cast,
    COALESCE(cr.roles, '{}') AS roles,
    COALESCE(ki.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CastRoles cr ON rm.movie_id = cr.movie_id
LEFT JOIN 
    KeywordInfo ki ON rm.movie_id = ki.movie_id
ORDER BY 
    rm.production_year DESC, rm.company_count DESC, rm.avg_title_length DESC;

This SQL query performs several operations that benchmark string processing, primarily focusing on movie titles, their accompanying cast, and associated keywords. The use of common table expressions (CTEs) allows for logical division and step-by-step computation:

1. **RankedMovies**: Calculates the total number of companies involved with each movie and the average length of movie titles longer than 10 characters.
2. **CastRoles**: Counts distinct cast members for each movie and aggregates their roles into an array.
3. **KeywordInfo**: Counts distinct keywords associated with each movie.
4. The final SELECT statement combines the results and includes conditional aggregation to handle movies without associated data. It then orders the results based on production year, company count, and average title length.
