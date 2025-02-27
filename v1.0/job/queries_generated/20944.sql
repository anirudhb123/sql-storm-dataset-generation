WITH RankedMovies AS (
    SELECT 
        a.movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_by_cast_size,
        COUNT(DISTINCT c.person_id) AS total_cast
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.movie_id = c.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        a.movie_id, t.title, t.production_year
), 
TopMovies AS (
    SELECT 
        movie_id,
        title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_size <= 3
), 
CompanyTitleInfo AS (
    SELECT 
        m.movie_id,
        GROUP_CONCAT(DISTINCT c.name) AS companies,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        CASE 
            WHEN SUM(m.info_type_id) FILTER (WHERE it.info = 'Tagline') IS NULL THEN 'No tagline available'
            ELSE SUM(m.info_type_id) FILTER (WHERE it.info = 'Tagline')
        END AS tagline
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info m ON mc.movie_id = m.movie_id
    JOIN 
        info_type it ON m.info_type_id = it.id
    GROUP BY 
        m.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    cti.companies,
    cti.keywords,
    cti.tagline,
    CASE 
        WHEN cti.companies IS NULL THEN 'Unknown Company'
        ELSE cti.companies
    END AS company_name,
    COUNT(DISTINCT c.person_role_id) OVER (PARTITION BY tm.movie_id) AS total_roles,
    STRING_AGG(DISTINCT CASE WHEN rc.note IS NULL THEN 'No note' ELSE rc.note END, ', ') AS role_notes
FROM 
    TopMovies tm
LEFT JOIN 
    CompanyTitleInfo cti ON tm.movie_id = cti.movie_id
LEFT JOIN 
    cast_info c ON tm.movie_id = c.movie_id
LEFT JOIN 
    role_type rt ON c.role_id = rt.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         note
     FROM 
         cast_info
     WHERE 
         nr_order IN (SELECT DISTINCT nr_order FROM cast_info ORDER BY nr_order DESC LIMIT 5)
    ) rc ON c.movie_id = rc.movie_id
WHERE 
    tm.production_year BETWEEN 2000 AND 2020
GROUP BY 
    tm.title, tm.production_year, cti.companies, cti.keywords, cti.tagline
ORDER BY 
    tm.production_year DESC, tm.title;
