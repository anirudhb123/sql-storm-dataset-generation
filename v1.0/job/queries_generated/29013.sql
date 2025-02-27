WITH NameCounts AS (
    SELECT
        p.id AS person_id,
        n.name,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM
        name n
    JOIN
        cast_info c ON n.id = c.person_id
    JOIN
        aka_name p ON n.id = p.person_id
    GROUP BY
        p.id, n.name
),
PopularMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM
        title m
    JOIN
        cast_info c ON m.id = c.movie_id
    GROUP BY
        m.id, m.title, m.production_year
    HAVING
        COUNT(DISTINCT c.person_id) >= 5
),
CompanyStats AS (
    SELECT
        mc.movie_id,
        json_agg(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM
        movie_companies mc
    JOIN
        company_name cn ON mc.company_id = cn.id
    GROUP BY
        mc.movie_id
),
KeywordStats AS (
    SELECT
        mk.movie_id,
        json_agg(DISTINCT k.keyword) AS keywords,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    GROUP BY
        mk.movie_id
)

SELECT 
    n.name, 
    n.movie_count,
    pm.title,
    pm.production_year,
    cs.companies,
    cs.company_count,
    ks.keywords,
    ks.keyword_count
FROM 
    NameCounts n
JOIN 
    PopularMovies pm ON n.movie_count > 0
JOIN 
    CompanyStats cs ON pm.movie_id = cs.movie_id
JOIN 
    KeywordStats ks ON pm.movie_id = ks.movie_id
ORDER BY 
    n.movie_count DESC, 
    pm.production_year DESC;
