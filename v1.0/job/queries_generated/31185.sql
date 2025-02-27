WITH RECURSIVE MovieHierarchy AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        0 AS level
    FROM
        aka_title t
    WHERE
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')  -- Filter to only include movies

    UNION ALL

    SELECT
        m.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM
        movie_link m
    JOIN
        MovieHierarchy mh ON m.movie_id = mh.movie_id
),

RankedMovies AS (
    SELECT
        mh.movie_id,
        mh.title,
        mh.production_year,
        RANK() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
    FROM
        MovieHierarchy mh
),

CompanyMovies AS (
    SELECT
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    JOIN
        company_type ct ON mc.company_type_id = ct.id
),

PersonalInfo AS (
    SELECT
        pi.person_id,
        MAX(CASE WHEN it.info = 'birthdate' THEN pi.info END) AS birthdate,
        MAX(CASE WHEN it.info = 'deathdate' THEN pi.info END) AS deathdate,
        COUNT(DISTINCT ci.movie_id) AS movies_count
    FROM
        person_info pi
    JOIN
        info_type it ON pi.info_type_id = it.id
    GROUP BY
        pi.person_id
)

SELECT
    ak.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    cm.company_name,
    cm.company_type,
    pi.birthdate,
    pi.deathdate,
    pi.movies_count,
    COALESCE(rm.title_rank, 0) AS title_rank,
    CASE 
        WHEN pi.deathdate IS NOT NULL THEN 'Deceased'
        WHEN pi.birthdate IS NOT NULL THEN 'Alive'
        ELSE 'Unknown'
    END AS status
FROM
    cast_info ci
JOIN
    aka_name ak ON ci.person_id = ak.person_id
JOIN
    RankedMovies rm ON ci.movie_id = rm.movie_id
LEFT JOIN
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN
    PersonalInfo pi ON ak.person_id = pi.person_id
WHERE
    rm.production_year BETWEEN 2000 AND 2023
    AND pi.movies_count > 5
ORDER BY
    rm.production_year DESC,
    rm.title;

-- This query combines several advanced SQL features: 
-- 1. A recursive CTE (MovieHierarchy) to traverse linked movies.
-- 2. A ranking system (RankedMovies) to assign ranks to movie titles within their year.
-- 3. A subquery (CompanyMovies) to get companies associated with each movie.
-- 4. Conditional aggregation (PersonalInfo) to gather birthdates and counts of movies per person.
-- 5. Diverse joins, outer joins, and complex predicates to filter and structure the data meaningfully.
