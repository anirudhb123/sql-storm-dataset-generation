WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_titles
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompositeName AS (
    SELECT 
        ak.person_id,
        STRING_AGG(ak.name, ', ') AS full_name,
        MAX(CASE WHEN ak.name IS NULL THEN 'Unknown' ELSE ak.name END) AS any_name
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
),
MovieCast AS (
    SELECT 
        cc.movie_id, 
        cc.person_id,
        c.role_id,
        COALESCE(c.note, 'No Role Specified') AS role_note,
        CASE 
            WHEN c.nr_order IS NULL THEN 0 
            ELSE c.nr_order 
        END AS order_num
    FROM 
        cast_info c
    LEFT JOIN 
        CompositeName cn ON c.person_id = cn.person_id
    WHERE 
        c.note IS NOT NULL OR c.note IS NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        COALESCE(SUM(mk.movie_id IS NOT NULL)::int, 0) AS keyword_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    WHERE 
        rm.title_rank = 1 AND
        rm.total_titles > 2
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    COUNT(DISTINCT mc.person_id) AS cast_count,
    MAX(mc.role_note) AS example_role_note,
    fm.keyword_count,
    CASE 
        WHEN fm.keyword_count BETWEEN 1 AND 5 THEN 'Few Keywords'
        WHEN fm.keyword_count BETWEEN 6 AND 10 THEN 'Moderate Keywords'
        ELSE 'Many Keywords'
    END AS keyword_category,
    RANK() OVER (ORDER BY fm.production_year DESC, COUNT(mc.person_id) DESC) AS movie_rank
FROM 
    FilteredMovies fm
LEFT JOIN 
    MovieCast mc ON fm.movie_id = mc.movie_id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.keyword_count
HAVING 
    COUNT(DISTINCT mc.person_id) > 1
ORDER BY 
    fm.production_year DESC, movie_rank
LIMIT 10;
