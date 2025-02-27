WITH Recursive MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        COALESCE(ARRAY_AGG(DISTINCT k.keyword) FILTER (WHERE k.keyword IS NOT NULL), ARRAY[]::text[]) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        SUM(CASE WHEN ci.nr_order IS NOT NULL THEN 1 ELSE 0 END) AS ordered_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id
), RankedMovies AS (
    SELECT 
        m.movie_id,
        m.movie_title,
        m.production_year,
        m.keywords,
        m.cast_count,
        m.ordered_cast_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.cast_count DESC, m.movie_title) AS rank
    FROM 
        MovieCTE m
), FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.keywords,
        rm.cast_count,
        rm.ordered_cast_count
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank <= 5 -- Top 5 movies per production year
)
SELECT 
    f.movie_id,
    f.movie_title,
    f.production_year,
    f.keywords,
    f.cast_count,
    f.ordered_cast_count,
    COALESCE((SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = f.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'box office')), 0) AS box_office_count,
    CASE 
        WHEN f.cast_count > 10 THEN 'Ensemble Cast'
        WHEN f.ordered_cast_count > 5 THEN 'Lead Roles'
        ELSE 'Unknown'
    END AS cast_type
FROM 
    FilteredMovies f
LEFT JOIN 
    title ti ON f.movie_id = ti.id
WHERE 
    (f.production_year IS NOT NULL OR f.production_year > 2000) 
    AND (f.keywords IS NOT NULL AND f.keywords <> '{}') 
ORDER BY 
    f.production_year DESC, f.cast_count DESC;
