WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles,
        t.kind_id
    FROM 
        aka_title t
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(mci.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
TitleDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        r.title_rank,
        mci.company_name,
        mci.company_type,
        mci.company_count,
        COALESCE(mk.keyword, 'No Keywords') AS keyword,
        CASE 
            WHEN r.production_year > 2000 THEN 'Modern Era' 
            WHEN r.production_year BETWEEN 1980 AND 2000 THEN 'Post Classic'
            ELSE 'Classic'
        END AS era
    FROM 
        RankedMovies r
    LEFT JOIN 
        MovieCompanyInfo mci ON r.movie_id = mci.movie_id
    LEFT JOIN 
        (
            SELECT 
                mk.movie_id, 
                STRING_AGG(mk.keyword, ', ') AS keyword
            FROM 
                movie_keyword mk
            GROUP BY 
                mk.movie_id
        ) AS mk ON r.movie_id = mk.movie_id
)
SELECT 
    td.title,
    td.production_year,
    td.era,
    td.company_name,
    td.company_type,
    td.company_count,
    COUNT(DISTINCT ci.person_id) AS cast_count,
    MAX(ti.info) AS movie_info
FROM 
    TitleDetails td
LEFT JOIN 
    complete_cast c ON td.movie_id = c.movie_id
LEFT JOIN 
    movie_info ti ON td.movie_id = ti.movie_id
LEFT JOIN 
    cast_info ci ON c.subject_id = ci.person_id
WHERE 
    td.title IS NOT NULL
    AND (td.production_year IS NOT NULL OR td.company_count > 1)
GROUP BY 
    td.title, td.production_year, td.era, td.company_name, td.company_type, td.company_count
HAVING 
    (SUM(CASE WHEN td.company_count > 1 THEN 1 ELSE 0 END) > 0 OR 
    COUNT(DISTINCT ci.person_id) > 5)
ORDER BY 
    td.production_year DESC, td.title_rank;
