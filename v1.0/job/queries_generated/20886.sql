WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MovieCompanyDetails AS (
    SELECT 
        m.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        CASE 
            WHEN m.note IS NULL THEN 'No Note'
            ELSE m.note
        END AS note,
        ROW_NUMBER() OVER (PARTITION BY m.movie_id ORDER BY ct.kind) AS company_rank
    FROM 
        movie_companies m
    JOIN 
        company_name c ON m.company_id = c.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieInfoDetails AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS movie_info_summary,
        COUNT(mi.id) AS info_count
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    r.title_id,
    r.title,
    r.production_year,
    mcd.company_name,
    mcd.company_type,
    COALESCE(mid.movie_info_summary, 'No Information') AS movie_info,
    mid.info_count,
    COALESCE(mcd.note, 'No Company Note') AS company_note
FROM 
    RankedMovies r
LEFT JOIN 
    MovieCompanyDetails mcd ON r.title_id = mcd.movie_id AND mcd.company_rank = 1 
LEFT JOIN 
    MovieInfoDetails mid ON r.title_id = mid.movie_id
WHERE 
    r.rank <= 5 
    AND r.production_year IS NOT NULL
ORDER BY 
    r.production_year DESC, 
    r.title;

