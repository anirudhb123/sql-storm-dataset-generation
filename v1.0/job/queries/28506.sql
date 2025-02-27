WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        a.kind_id,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank
    FROM aka_title a
    WHERE a.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ct.kind AS category,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM RankedMovies rm
    LEFT JOIN movie_companies mc ON mc.movie_id = rm.movie_id
    LEFT JOIN company_name cn ON mc.company_id = cn.id
    LEFT JOIN kind_type ct ON rm.kind_id = ct.id
    WHERE rm.rank <= 10
    GROUP BY rm.movie_id, rm.title, rm.production_year, ct.kind
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        tm.production_year,
        tm.category,
        tm.company_count,
        tm.companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT pi.info, '; ') AS person_info
    FROM TopMovies tm
    LEFT JOIN movie_keyword mk ON tm.movie_id = mk.movie_id
    LEFT JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN cast_info ci ON tm.movie_id = ci.movie_id
    LEFT JOIN person_info pi ON ci.person_id = pi.person_id
    GROUP BY tm.movie_id, tm.title, tm.production_year, tm.category, tm.company_count, tm.companies
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.category,
    md.company_count,
    md.companies,
    md.keywords,
    md.person_info
FROM MovieDetails md
ORDER BY md.production_year DESC, md.title;
