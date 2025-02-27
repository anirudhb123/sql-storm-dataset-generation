WITH MovieStats AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        AVG(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_as_lead,
        COUNT(DISTINCT mci.company_id) FILTER (WHERE ct.kind = 'Production') AS production_companies
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    LEFT JOIN 
        movie_companies mci ON at.movie_id = mci.movie_id
    LEFT JOIN 
        company_type ct ON mci.company_type_id = ct.id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title, 
        production_year,
        total_cast,
        avg_as_lead,
        production_companies,
        ROW_NUMBER() OVER (ORDER BY total_cast DESC, production_companies DESC) AS rn
    FROM 
        MovieStats
),
ExternalLinks AS (
    SELECT 
        m1.title AS main_movie,
        m2.title AS linked_movie,
        lt.link AS link_type
    FROM 
        movie_link ml
    JOIN 
        title m1 ON ml.movie_id = m1.id
    JOIN 
        title m2 ON ml.linked_movie_id = m2.id
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    tm.avg_as_lead,
    tm.production_companies,
    el.linked_movie,
    el.link_type
FROM 
    TopMovies tm
LEFT JOIN 
    ExternalLinks el ON tm.title = el.main_movie
WHERE 
    tm.rn <= 10
ORDER BY 
    tm.total_cast DESC, 
    tm.production_companies DESC,
    tm.title;
