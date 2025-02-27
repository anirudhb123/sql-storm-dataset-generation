WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        AVG(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS has_note_ratio
    FROM title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        co.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS total_companies
    FROM movie_companies mc
    JOIN company_name co ON mc.company_id = co.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    GROUP BY mc.movie_id, co.name, ct.kind
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    GROUP BY mk.movie_id
)
SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    cd.company_name,
    cd.company_type,
    cd.total_companies,
    kd.keywords,
    md.has_note_ratio
FROM MovieDetails md
LEFT JOIN CompanyDetails cd ON md.movie_id = cd.movie_id
LEFT JOIN KeywordDetails kd ON md.movie_id = kd.movie_id
WHERE 
    (md.production_year IS NULL OR md.production_year > 2000)
    AND (cd.total_companies IS NULL OR cd.total_companies > 1)
ORDER BY 
    md.production_year DESC,
    md.cast_count DESC,
    md.title;
