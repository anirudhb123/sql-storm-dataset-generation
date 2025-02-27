WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        title, 
        production_year,
        total_cast
    FROM 
        RankedMovies
    WHERE 
        year_rank <= 5
),
CompanyContributions AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS num_companies
    FROM 
        movie_companies mc
    JOIN 
        TopMovies tm ON mc.movie_id = tm.movie_id
    GROUP BY 
        mc.movie_id
),
MovieInfoWithKeywords AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_info mi
    JOIN 
        movie_keyword mk ON mi.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_cast,
    COALESCE(cc.num_companies, 0) AS num_companies,
    COALESCE(mik.keywords, 'No keywords') AS keywords_info
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyContributions cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    MovieInfoWithKeywords mik ON tm.movie_id = mik.movie_id
ORDER BY 
    tm.production_year DESC, total_cast DESC
LIMIT 10;

This SQL query provides a performance benchmark by combining multiple CTEs (Common Table Expressions) to aggregate relevant data about top films from the **aka_title** table, including cast counts and associated company contributions, along with keyword data. The use of `STRING_AGG` for aggregating keywords and `ROW_NUMBER` for ranking movies by production year introduces complexity. It also gracefully addresses potential NULL values and makes use of COALESCE to ensure robust and informative output. The overall structure showcases not only the relationships among the tables but also demands an optimizer's intricate handling, making it ideal for performance benchmarking.
