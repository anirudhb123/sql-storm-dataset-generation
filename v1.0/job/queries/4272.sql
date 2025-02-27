
WITH MovieRankings AS (
    SELECT 
        t.title, 
        t.production_year, 
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.movie_id) DESC) AS rank
    FROM title t
    JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.title, t.production_year
),
CompanyMovieData AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        COUNT(DISTINCT c.id) AS company_count
    FROM movie_companies m
    JOIN company_name c ON m.company_id = c.id
    JOIN company_type ct ON m.company_type_id = ct.id
    GROUP BY m.movie_id, c.name, ct.kind
),
KeywordStats AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
),
FinalReport AS (
    SELECT 
        t.title,
        t.production_year,
        COALESCE(cmp.company_name, 'Unknown') AS company_name,
        COALESCE(cmp.company_type, 'N/A') AS company_type,
        mk.keywords,
        mvr.rank
    FROM title t
    LEFT JOIN CompanyMovieData cmp ON t.id = cmp.movie_id
    LEFT JOIN KeywordStats mk ON t.id = mk.movie_id
    JOIN MovieRankings mvr ON t.title = mvr.title AND t.production_year = mvr.production_year
    WHERE t.production_year >= 2000
)
SELECT * FROM FinalReport
ORDER BY production_year ASC, rank ASC;
