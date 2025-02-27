WITH MovieDetails AS (
    SELECT 
        a.id AS aka_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT c.person_id) AS cast_ids,
        COUNT(mc.id) AS company_count,
        AVG(pi.info) FILTER (WHERE pi.info_type_id IN (SELECT id FROM info_type WHERE info = 'Rating')) AS average_rating
    FROM 
        aka_title t
    LEFT JOIN 
        aka_name a ON t.id = a.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        movie_info pi ON t.id = pi.movie_id
    GROUP BY 
        a.id, t.title, t.production_year
),
RankedMovies AS (
    SELECT 
        md.*,
        ROW_NUMBER() OVER (PARTITION BY production_year ORDER BY average_rating DESC NULLS LAST) AS rn,
        COUNT(*) OVER (PARTITION BY production_year) AS total_movies
    FROM 
        MovieDetails md
)
SELECT 
    rm.aka_id,
    rm.title,
    rm.production_year,
    rm.cast_ids,
    rm.company_count,
    rm.average_rating,
    CASE 
        WHEN rm.average_rating IS NULL THEN 'No Rating Available'
        ELSE 'Rating Available'
    END AS rating_status,
    (SELECT STRING_AGG(name, ', ') FROM name n WHERE n.imdb_id IN (SELECT unnest(rm.cast_ids))) AS cast_names
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 5 AND rm.production_year = (SELECT MAX(production_year) FROM RankedMovies)
ORDER BY 
    rm.average_rating DESC NULLS LAST;
