
WITH RecursiveTitleCTE AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
RankedAkaNames AS (
    SELECT 
        an.id AS aka_id,
        an.name,
        an.person_id,
        ROW_NUMBER() OVER (PARTITION BY an.person_id ORDER BY an.name) AS name_rank
    FROM 
        aka_name an
),
CompanyMovieInfo AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieGenreCount AS (
    SELECT 
        mt.movie_id,
        COUNT(DISTINCT mt.keyword_id) AS genre_count
    FROM 
        movie_keyword mt
    GROUP BY 
        mt.movie_id
)
SELECT 
    RCTE.title_id,
    RCTE.title,
    COALESCE(an.name, 'Unknown Actor') AS actor_name,
    COALESCE(c.company_names, 'No Companies') AS related_companies,
    COALESCE(mg.genre_count, 0) AS genre_count,
    RCTE.production_year,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = RCTE.title_id AND ci.note IS NOT NULL) AS cast_note_count,
    (SELECT AVG(COALESCE(ci.nr_order, 0)) 
     FROM cast_info ci 
     WHERE ci.movie_id = RCTE.title_id) AS avg_order
FROM 
    RecursiveTitleCTE RCTE
LEFT JOIN 
    RankedAkaNames an ON RCTE.title_id = an.person_id
LEFT JOIN 
    CompanyMovieInfo c ON RCTE.title_id = c.movie_id
LEFT JOIN 
    MovieGenreCount mg ON RCTE.title_id = mg.movie_id
WHERE 
    (RCTE.title IS NOT NULL OR RCTE.production_year > 2000)
    AND (an.name_rank <= 5 OR an.aka_id IS NULL)
GROUP BY 
    RCTE.title_id,
    RCTE.title,
    an.name,
    c.company_names,
    mg.genre_count,
    RCTE.production_year
ORDER BY 
    RCTE.production_year DESC,
    avg_order ASC,
    RCTE.title;
