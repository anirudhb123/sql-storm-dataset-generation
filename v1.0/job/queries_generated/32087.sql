WITH RECURSIVE MovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title AS mt
    LEFT JOIN 
        movie_companies AS mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name AS cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info AS ci ON mt.id = ci.movie_id
    GROUP BY 
        mt.id
    HAVING 
        mt.production_year > 2000
),

CastRoles AS (
    SELECT 
        ci.movie_id,
        ARRAY_AGG(DISTINCT rt.role) AS roles,
        COUNT(DISTINCT ci.person_id) AS total_roles
    FROM 
        cast_info AS ci
    LEFT JOIN 
        role_type AS rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),

RankingInfo AS (
    SELECT 
        mt.movie_id,
        mt.title,
        mt.production_year,
        mt.companies,
        cr.roles,
        cr.total_roles,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.cast_count DESC) AS rank_within_year
    FROM 
        MovieCTE AS mt
    JOIN 
        CastRoles AS cr ON mt.movie_id = cr.movie_id
)

SELECT 
    ri.title,
    ri.production_year,
    ri.companies,
    ri.roles,
    ri.total_roles,
    ri.rank_within_year
FROM 
    RankingInfo AS ri
WHERE 
    ri.total_roles > 5 AND 
    ri.rank_within_year <= 10
ORDER BY 
    ri.production_year DESC, 
    ri.rank_within_year;
In this SQL query, we are performing several complex operations:

1. We define a recursive common table expression (`MovieCTE`) that gathers information about movies, including their titles, production years, associated companies, and the number of unique cast members. We filter for movies released after the year 2000.

2. We create another CTE (`CastRoles`) that aggregates the roles associated with each movie, counting how many distinct roles exist.

3. We further refine the data in the `RankingInfo` CTE by ranking the movies based on their cast counts per production year using window functions.

4. Finally, we select from the ranked result while applying additional filters to only show movies that have more than 5 roles and are ranked within the top 10 for their production year. The results are ordered by the production year in descending order and then by the rank.

This complex query utilizes outer joins, grouped aggregations, window functions, and various SQL constructs, making it suitable for performance benchmarking.
