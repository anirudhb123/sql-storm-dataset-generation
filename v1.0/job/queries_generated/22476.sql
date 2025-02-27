WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank,
        COALESCE(mk.keyword, 'No Keyword') AS movie_keyword,
        COUNT(ci.id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, t.production_year, t.kind_id, mk.keyword
), FilteredMovies AS (
    SELECT 
        *,
        CASE 
            WHEN total_cast >= 10 THEN 'Ensemble Cast'
            WHEN total_cast BETWEEN 5 AND 9 THEN 'Small Cast'
            ELSE 'Few Actors'
        END AS cast_size
    FROM 
        RankedMovies
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(kt.keyword, 'Unspecified') AS keyword,
    f.cast_size,
    SUM(mci.note IS NOT NULL) OVER (PARTITION BY f.production_year) AS companies_with_notes,
    STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS company_names,
    COUNT(DISTINCT ci.person_id) AS unique_actors
FROM 
    FilteredMovies f
LEFT JOIN 
    movie_companies mci ON mci.movie_id = f.id
LEFT JOIN 
    company_name cn ON mci.company_id = cn.id
LEFT JOIN 
    aka_name an ON an.person_id IN (SELECT DISTINCT ci.person_id FROM cast_info ci WHERE ci.movie_id = f.id)
LEFT JOIN 
    keyword kt ON f.movie_keyword = kt.id
WHERE 
    f.year_rank <= 5 AND f.production_year >= 2000
GROUP BY 
    f.title, f.production_year, f.cast_size
ORDER BY 
    f.production_year DESC, f.title;
