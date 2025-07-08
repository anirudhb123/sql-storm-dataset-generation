
WITH RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        m.kind_id,
        COALESCE(ARRAY_AGG(DISTINCT k.keyword), ARRAY_CONSTRUCT()) AS keywords,
        COALESCE(ARRAY_AGG(DISTINCT c.name), ARRAY_CONSTRUCT()) AS companies,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.kind_id ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    GROUP BY 
        m.id, m.title, m.production_year, m.kind_id
),

TopRankedMovies AS (
    SELECT
        movie_id,
        movie_title,
        production_year,
        keywords,
        companies,
        cast_count
    FROM
        RankedMovies
    WHERE
        rank <= 10
)

SELECT
    t.movie_id,
    t.movie_title,
    t.production_year,
    t.keywords,
    t.companies,
    t.cast_count,
    ARRAY_AGG(DISTINCT p.info) AS additional_person_info
FROM
    TopRankedMovies t
LEFT JOIN 
    complete_cast cc ON t.movie_id = cc.movie_id
LEFT JOIN 
    person_info p ON cc.subject_id = p.person_id
GROUP BY
    t.movie_id, t.movie_title, t.production_year, t.keywords, t.companies, t.cast_count
ORDER BY
    t.cast_count DESC;
