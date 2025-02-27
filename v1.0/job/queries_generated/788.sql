WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'feature'))
),
SelectedCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        r.role,
        COUNT(*) OVER (PARTITION BY c.movie_id) AS cast_count
    FROM 
        cast_info c
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.nr_order IS NOT NULL
),
MoviesWithDetails AS (
    SELECT 
        m.movie_id,
        COALESCE(avg_rating.avg_rating, 0) AS average_rating,
        COALESCE(cast.cast_count, 0) AS number_of_cast,
        m.title,
        m.production_year
    FROM 
        RankedMovies m
    LEFT JOIN (
        SELECT 
            movie_id, 
            AVG(CAST(info AS DECIMAL)) AS avg_rating 
        FROM 
            movie_info 
        WHERE 
            info_type_id = (SELECT id FROM info_type WHERE info = 'rating') 
        GROUP BY 
            movie_id
    ) avg_rating ON m.movie_id = avg_rating.movie_id
    LEFT JOIN SelectedCast cast ON m.movie_id = cast.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.average_rating,
    md.number_of_cast,
    cn.name AS company_name
FROM 
    MoviesWithDetails md
LEFT JOIN 
    movie_companies mc ON md.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    md.average_rating > 7 AND 
    (md.number_of_cast > 10 OR md.production_year < 2000) 
ORDER BY 
    md.production_year DESC, md.average_rating DESC;
