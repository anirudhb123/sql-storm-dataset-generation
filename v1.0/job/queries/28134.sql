WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        r.role,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order ASC) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT rm.role || ' (' || rm.nr_order || ')', ', ') AS cast,
        MAX(rm.actor_rank) AS cast_size
    FROM 
        RankedMovies rm
    WHERE 
        LOWER(rm.title) LIKE '%action%'  
    GROUP BY 
        rm.movie_id,
        rm.title,
        rm.production_year
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.cast,
    fm.cast_size
FROM 
    FilteredMovies fm
WHERE 
    fm.cast_size > 5  
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;