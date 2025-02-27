WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
), 
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        STRING_AGG(DISTINCT an.name, ', ') AS cast_names
    FROM 
        cast_info ci
    JOIN 
        aka_name an ON ci.person_id = an.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        mi.info
    FROM
        aka_title m
    LEFT JOIN
        movie_info mi ON m.id = mi.movie_id
    WHERE
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Synopsis' OR info = 'Summary')
)
SELECT 
    rt.title_id,
    rt.title,
    rt.production_year,
    cd.total_cast,
    cd.cast_names,
    mi.info AS movie_summary
FROM 
    RankedTitles rt
LEFT JOIN 
    CastDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    MovieInfo mi ON rt.title_id = mi.movie_id
WHERE 
    rt.year_rank <= 10
ORDER BY 
    rt.production_year DESC, 
    cd.total_cast DESC
LIMIT 50;

This SQL query achieves the following:
- It first ranks titles by production year and filters them to the top 10 per year in the `RankedTitles` Common Table Expression (CTE).
- Then, it aggregates the cast information for each movie in the `CastDetails` CTE, counting distinct cast members and concatenating their names into a string.
- The `MovieInfo` CTE extracts movie summaries and synopses.
- Lastly, the main SELECT statement brings together the title details, cast information, and movie summary, filtering and sorting the records for benchmarking purposes while limiting the output to 50 rows.
