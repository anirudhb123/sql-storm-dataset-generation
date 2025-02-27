WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        a.name AS aka_name,
        t.title AS movie_title,
        t.production_year,
        t.kind_id,
        c.role_id AS cast_role,
        c.nr_order,
        cp.kind AS company_type,
        m.info AS movie_info
    FROM aka_title AS t
    JOIN cast_info AS c ON t.id = c.movie_id
    JOIN aka_name AS a ON c.person_id = a.person_id
    JOIN movie_companies AS mc ON t.id = mc.movie_id
    JOIN company_type AS cp ON mc.company_type_id = cp.id
    LEFT JOIN movie_info AS m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
    WHERE 
        t.production_year BETWEEN 2000 AND 2020
        AND cp.kind ILIKE '%production%'
),
RoleStatistics AS (
    SELECT 
        cast_role,
        COUNT(*) AS role_count,
        STRING_AGG(DISTINCT aka_name, ', ') AS actors
    FROM MovieDetails
    GROUP BY cast_role
),
MovieStatistics AS (
    SELECT 
        movie_title,
        production_year,
        COUNT(DISTINCT aka_id) AS total_actors,
        STRING_AGG(DISTINCT company_type, ', ') AS companies_involved,
        MAX(role_count) AS max_role_count
    FROM MovieDetails
    JOIN RoleStatistics ON MovieDetails.cast_role = RoleStatistics.cast_role
    GROUP BY movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    total_actors,
    companies_involved,
    max_role_count
FROM MovieStatistics
WHERE total_actors >= 5
ORDER BY production_year DESC, total_actors DESC;
