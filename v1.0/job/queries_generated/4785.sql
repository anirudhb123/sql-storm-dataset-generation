WITH MovieRankings AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM aka_title at
    LEFT JOIN cast_info ci ON at.id = ci.movie_id
    GROUP BY at.title, at.production_year
),
TopMovies AS (
    SELECT 
        mr.movie_title,
        mr.production_year,
        mr.cast_count
    FROM MovieRankings mr
    WHERE mr.rank <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    GROUP BY mc.movie_id
),
MovieDetails AS (
    SELECT 
        tm.movie_title,
        tm.production_year,
        ci.companies,
        kv.keyword,
        COUNT(mi.info) AS info_count
    FROM TopMovies tm
    LEFT JOIN CompanyInfo ci ON tm.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN movie_keyword mk ON mk.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title)
    LEFT JOIN keyword kv ON mk.keyword_id = kv.id
    LEFT JOIN movie_info mi ON mi.movie_id = (SELECT id FROM aka_title WHERE title = tm.movie_title)
    GROUP BY tm.movie_title, tm.production_year, ci.companies, kv.keyword
)
SELECT 
    md.movie_title,
    md.production_year,
    COALESCE(md.companies, 'No Companies') AS companies,
    COALESCE(md.keyword, 'No Keywords') AS keyword,
    md.info_count
FROM MovieDetails md
WHERE md.production_year > 2000
ORDER BY md.production_year DESC, md.info_count DESC;
