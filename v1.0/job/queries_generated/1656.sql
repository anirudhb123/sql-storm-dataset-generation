WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names,
        COUNT(DISTINCT kw.keyword) AS keyword_count
    FROM
        aka_title t
    LEFT JOIN
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN
        cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN
        aka_name c ON ci.person_id = c.person_id
    LEFT JOIN
        movie_keyword mw ON t.id = mw.movie_id
    LEFT JOIN
        keyword kw ON mw.keyword_id = kw.id
    GROUP BY 
        t.id
),
CompanyAggregates AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TopMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.cast_names,
        md.keyword_count,
        ca.companies,
        ca.company_count,
        ROW_NUMBER() OVER (PARTITION BY md.production_year ORDER BY md.keyword_count DESC) AS rn
    FROM 
        MovieDetails md
    LEFT JOIN 
        CompanyAggregates ca ON md.movie_id = ca.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_names,
    tm.companies,
    COALESCE(tm.company_count, 0) AS total_companies,
    tm.keyword_count
FROM 
    TopMovies tm
WHERE 
    tm.rn <= 5
ORDER BY 
    tm.production_year DESC, tm.keyword_count DESC;
