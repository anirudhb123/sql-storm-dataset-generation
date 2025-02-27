WITH filtered_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        kt.kind AS movie_kind,
        STRING_AGG(DISTINCT ak.name, ', ') AS aliases
    FROM 
        aka_title ak
    JOIN 
        title t ON ak.movie_id = t.id
    JOIN 
        kind_type kt ON t.kind_id = kt.id
    WHERE 
        t.production_year >= 2000 -- Filtering movies from the year 2000 onward
    GROUP BY 
        t.id, t.title, t.production_year, kt.kind
),
movie_cast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(p.name, ' as ', rt.role), ', ') AS cast_details
    FROM 
        cast_info c
    JOIN 
        aka_name p ON c.person_id = p.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    WHERE 
        c.nr_order <= 5 -- Only consider up to first 5 cast members
    GROUP BY 
        c.movie_id
)
SELECT 
    fm.movie_id,
    fm.movie_title,
    fm.production_year,
    fm.movie_kind,
    fm.aliases,
    mc.cast_details
FROM 
    filtered_movies fm
LEFT JOIN 
    movie_cast mc ON fm.movie_id = mc.movie_id
ORDER BY 
    fm.production_year DESC, fm.movie_title;
