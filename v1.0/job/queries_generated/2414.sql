WITH MovieDetails AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        COUNT(c.person_id) AS total_cast,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(c.person_id) DESC) AS rank_by_cast
    FROM 
        aka_title AS a
    LEFT JOIN 
        cast_info AS c ON a.id = c.movie_id
    LEFT JOIN 
        movie_keyword AS mk ON a.id = mk.movie_id
    LEFT JOIN 
        keyword AS k ON mk.keyword_id = k.id
    GROUP BY 
        a.id, a.title, a.production_year, a.kind_id
),
TopMovies AS (
    SELECT 
        md.* 
    FROM 
        MovieDetails md
    WHERE 
        md.rank_by_cast <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type 
    FROM 
        movie_companies AS mc
    JOIN 
        company_name AS cn ON mc.company_id = cn.id
    JOIN 
        company_type AS ct ON mc.company_type_id = ct.id
),
FinalBenchmark AS (
    SELECT 
        tm.title,
        tm.production_year,
        COUNT(ci.person_id) AS cast_count,
        COALESCE(SUM(CASE WHEN tm.production_year >= 2000 THEN 1 ELSE 0 END), 0) AS movies_since_2000,
        CI.company_name,
        COUNT(CAST_INFO.id) AS total_contributions
    FROM 
        TopMovies AS tm
    LEFT JOIN 
        cast_info AS ci ON tm.movie_id = ci.movie_id
    LEFT JOIN 
        CompanyInfo AS CI ON tm.movie_id = CI.movie_id
    GROUP BY 
        tm.title, tm.production_year, CI.company_name
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    cast_count IS NOT NULL
ORDER BY 
    production_year DESC, cast_count DESC;
