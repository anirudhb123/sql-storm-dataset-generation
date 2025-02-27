WITH RecursiveMovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS actor_role,
        ROW_NUMBER() OVER (PARTITION BY c.movie_id ORDER BY c.nr_order) AS role_order
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(DISTINCT mc.actor_name) AS total_actors,
        MAX(mc.role_order) AS max_roles
    FROM 
        title t
    LEFT JOIN 
        RecursiveMovieCast mc ON t.id = mc.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
MoviesWithKeywords AS (
    SELECT 
        t.title,
        t.production_year,
        ARRAY_AGG(DISTINCT k.keyword) AS keywords,
        COALESCE(SUM(mk.id::integer), 0) AS keyword_count
    FROM 
        title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.total_actors,
        rm.max_roles,
        kw.keywords,
        kw.keyword_count
    FROM 
        RankedMovies rm
    JOIN 
        MoviesWithKeywords kw ON rm.title = kw.title AND rm.production_year = kw.production_year
    WHERE 
        rm.total_actors > 0 AND 
        (kw.keyword_count > 1 OR kw.keyword_count IS NULL)
)
SELECT 
    fm.title,
    fm.production_year,
    fm.total_actors,
    fm.max_roles,
    fm.keywords,
    CASE 
        WHEN fm.keyword_count IS NULL THEN 'No keywords available'
        ELSE 'Keyword Count: ' || fm.keyword_count::text
    END AS keyword_info
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.total_actors DESC, 
    fm.max_roles ASC
FETCH FIRST 10 ROWS ONLY;
