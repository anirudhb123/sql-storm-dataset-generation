WITH RECURSIVE MoviePath AS (
    SELECT 
        mt.movie_id,
        1 AS depth,
        ARRAY[mt.movie_id] AS path
    FROM 
        movie_companies AS mc
    JOIN 
        aka_title AS mt ON mc.movie_id = mt.movie_id 
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'PRODUCER')
    UNION ALL
    SELECT 
        mc.movie_id, 
        mp.depth + 1,
        mp.path || mc.movie_id
    FROM 
        MoviePath AS mp
    JOIN 
        movie_companies AS mc ON mc.movie_id = mp.movie_id
    WHERE 
        mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'DIRECTOR')
    AND NOT mc.movie_id = ANY(mp.path)  -- Prevent cycles
),
RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        COUNT(m.id) AS num_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(m.id) DESC) AS rank_number
    FROM 
        aka_title AS t
    LEFT JOIN 
        cast_info AS ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name AS m ON ci.person_id = m.person_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        rm.title,
        rm.production_year,
        rm.num_actors
    FROM 
        RankedMovies AS rm
    WHERE 
        rm.num_actors > 0 AND rm.rank_number <= 5
)
SELECT 
    COALESCE(p.movie_id, f.title) AS movie_or_film,
    f.production_year,
    f.num_actors, 
    'Ranked' AS source
FROM 
    FilteredMovies AS f
FULL OUTER JOIN 
    MoviePath AS p ON f.production_year = (SELECT production_year FROM aka_title WHERE id = p.movie_id LIMIT 1)
WHERE 
    f.num_actors IS NOT NULL OR p.movie_id IS NOT NULL
ORDER BY 
    f.production_year DESC, 
    f.num_actors DESC, 
    p.movie_id IS NULL;

