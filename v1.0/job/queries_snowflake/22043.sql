
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM aka_title t
    WHERE t.production_year IS NOT NULL
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        MAX(c.name) AS latest_company_name
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    GROUP BY mc.movie_id
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_cast_count,
        SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS roles_count
    FROM cast_info ci
    GROUP BY ci.movie_id
),
MoviesWithKeywords AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    R.title,
    COALESCE(CMC.company_count, 0) AS company_count,
    COALESCE(RC.distinct_cast_count, 0) AS cast_count,
    COALESCE(MKW.keywords, 'N/A') AS keywords,
    R.production_year,
    CASE 
        WHEN R.title_rank % 2 = 0 THEN 'Even Rank'
        ELSE 'Odd Rank'
    END AS rank_description
FROM RankedMovies R
LEFT JOIN CompanyMovieCounts CMC ON R.movie_id = CMC.movie_id
LEFT JOIN CastRoleCounts RC ON R.movie_id = RC.movie_id
LEFT JOIN MoviesWithKeywords MKW ON R.movie_id = MKW.movie_id
WHERE 
    (R.production_year BETWEEN 2000 AND 2023 OR R.production_year IS NULL)
    AND (R.title LIKE '%the%' OR R.title IS NULL)
ORDER BY R.production_year DESC, R.title;
