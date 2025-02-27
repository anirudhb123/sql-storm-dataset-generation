WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    GROUP BY 
        t.id, t.title, t.production_year
    
    UNION ALL
    
    SELECT 
        m.movie_id,
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS aka_names
    FROM 
        MovieCTE m
    JOIN 
        movie_link ml ON m.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
    JOIN 
        aka_title ak ON t.id = ak.movie_id
    WHERE 
        m.movie_id <> ml.linked_movie_id
    GROUP BY 
        m.movie_id, t.title, t.production_year
),
MovieCast AS (
    SELECT 
        t.id AS movie_id,
        COUNT(DISTINCT c.person_id) AS total_cast,
        MAX(ci.nr_order) AS highest_role_order
    FROM 
        title t 
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        comp_cast_type ct ON c.person_role_id = ct.id
    GROUP BY 
        t.id
),
FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        m.aka_names,
        c.total_cast,
        c.highest_role_order,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY c.total_cast DESC) AS rn
    FROM 
        MovieCTE m
    JOIN 
        MovieCast c ON m.movie_id = c.movie_id
)
SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.aka_names,
    f.total_cast,
    f.highest_role_order
FROM 
    FilteredMovies f
WHERE 
    f.rn <= 5
ORDER BY 
    f.production_year DESC, f.total_cast DESC;
