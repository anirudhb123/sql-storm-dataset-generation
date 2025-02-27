
WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        COALESCE(c.kind, 'Unknown') AS movie_kind,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rnk
    FROM 
        aka_title a
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    LEFT JOIN 
        kind_type c ON a.kind_id = c.id
    GROUP BY 
        a.title, a.production_year, c.kind
),
FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        movie_kind, 
        company_count
    FROM 
        RankedMovies
    WHERE 
        movie_kind IS NOT NULL AND production_year > 2000
),
MaxCompanyCount AS (
    SELECT 
        MAX(company_count) AS max_count 
    FROM 
        FilteredMovies
),
FinalMovies AS (
    SELECT 
        f.title, 
        f.production_year, 
        f.movie_kind, 
        f.company_count
    FROM 
        FilteredMovies f
    JOIN 
        MaxCompanyCount m ON f.company_count = m.max_count
),
TitleSummary AS (
    SELECT 
        fm.title, 
        fm.production_year, 
        fm.movie_kind, 
        ROW_NUMBER() OVER (ORDER BY fm.production_year DESC) AS movie_rank,
        CASE 
            WHEN fm.company_count IS NULL THEN 'No Companies'
            WHEN fm.company_count > 10 THEN 'Popular'
            ELSE 'Niche'
        END AS popularity_indication
    FROM 
        FinalMovies fm
)
SELECT 
    t.title,
    t.production_year,
    t.movie_kind,
    t.movie_rank,
    t.popularity_indication,
    CASE 
        WHEN t.popularity_indication = 'Popular' THEN CONCAT(t.title, ' - A blockbuster of ', t.production_year)
        ELSE CONCAT(t.title, ' - A hidden gem from ', t.production_year)
    END AS title_description,
    pi.person_id,
    pi.info
FROM 
    TitleSummary t
LEFT JOIN 
    person_info pi ON pi.person_id IN (
        SELECT DISTINCT ci.person_id 
        FROM cast_info ci 
        JOIN aka_name an ON ci.person_id = an.person_id
        WHERE ci.movie_id IN (
            SELECT a.id FROM aka_title a WHERE a.title = t.title AND a.production_year = t.production_year
        )
    )
WHERE 
    t.movie_rank <= 5 
ORDER BY 
    t.movie_rank;
