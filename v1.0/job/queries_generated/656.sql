WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        COALESCE(string_agg(DISTINCT cn.name, ', '), 'No Companies') AS companies
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_keyword mk ON tm.title = (SELECT title FROM aka_title WHERE id = mk.movie_id)
    LEFT JOIN 
        movie_companies mc ON tm.title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        tm.title, tm.production_year, mk.keyword
)
SELECT 
    md.title,
    md.production_year,
    md.keyword,
    md.companies,
    COUNT(DISTINCT pi.info) AS person_infos,
    SUM(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count
FROM 
    MovieDetails md
LEFT JOIN 
    person_info pi ON EXISTS (
        SELECT 1 FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = md.title)
    ) AND pi.person_id IN (
        SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = (SELECT id FROM aka_title WHERE title = md.title)
    )
GROUP BY 
    md.title, md.production_year, md.keyword, md.companies
ORDER BY 
    md.production_year DESC, md.total_cast DESC;
