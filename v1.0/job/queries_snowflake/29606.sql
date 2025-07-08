
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.id) AS cast_count,
        LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS cast_names,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast_count
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),

TopRatedMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.cast_count,
        m.cast_names,
        r.info AS movie_rating
    FROM 
        RankedMovies m
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    LEFT JOIN 
        info_type r ON mi.info_type_id = r.id
    WHERE 
        r.info LIKE '%rating%' 
        AND m.rank_by_cast_count <= 5
)

SELECT 
    t.title,
    t.production_year,
    t.cast_count,
    t.cast_names,
    COALESCE(t.movie_rating, 'No Rating') AS movie_rating
FROM 
    TopRatedMovies t
ORDER BY 
    t.production_year DESC, t.cast_count DESC;
