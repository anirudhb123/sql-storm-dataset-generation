WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        rn.rank,
        row_number() OVER (PARTITION BY a.production_year ORDER BY a.production_year DESC, a.title) AS year_rank,
        COUNT(b.id) AS cast_count
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info b ON a.id = b.movie_id
    JOIN 
        (SELECT 
            movie_id, 
            COUNT(role_id) AS role_count 
         FROM 
            cast_info 
         WHERE 
            person_role_id IS NOT NULL 
         GROUP BY movie_id 
        ) rc ON a.id = rc.movie_id
    LEFT JOIN 
        movie_info mi ON a.id = mi.movie_id
    WHERE 
        a.production_year IS NOT NULL
        AND a.title NOT LIKE '%(dummy)%'
        AND COALESCE(mi.info, 'not available') != 'not available'
    GROUP BY 
        a.id, a.title, a.production_year, rn.rank
    ORDER BY 
        a.production_year DESC,
        year_rank
),
SubQueryForRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.role_id) AS total_roles,
        SUM(CASE WHEN ci.note IS NULL THEN 1 ELSE 0 END) AS null_notes_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
HighlyRatedMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank >= 8 AND cast_count > 0
),
FinalSelection AS (
    SELECT 
        m.movie_title,
        m.production_year,
        r.total_roles,
        r.null_notes_count,
        COUNT(DISTINCT c.person_id) AS unique_cast
    FROM 
        HighlyRatedMovies m
    LEFT JOIN 
        SubQueryForRoles r ON m.movie_id = r.movie_id
    LEFT JOIN 
        cast_info c ON m.movie_title = c.movie_id
    WHERE 
        (m.production_year BETWEEN 2000 AND 2023 OR m.production_year IS NULL)
        AND (m.movie_title ILIKE '%action%' OR r.total_roles > 3)
    GROUP BY 
        m.movie_title, m.production_year, r.total_roles, r.null_notes_count
),
DistinctTitles AS (
    SELECT DISTINCT 
        f.movie_title, 
        f.production_year 
    FROM 
        FinalSelection f 
    WHERE 
        f.production_year IS NOT NULL
)
SELECT 
    dt.movie_title,
    dt.production_year,
    f.total_roles,
    f.null_notes_count,
    f.unique_cast,
    CASE 
        WHEN f.unique_cast <= 5 THEN 'Small Cast'
        WHEN f.unique_cast > 5 AND f.unique_cast <= 15 THEN 'Medium Cast'
        ELSE 'Large Cast'
    END AS cast_size
FROM 
    DistinctTitles dt
JOIN 
    FinalSelection f ON dt.movie_title = f.movie_title
WHERE 
    dt.movie_title IS NOT NULL
ORDER BY 
    f.production_year DESC, 
    f.unique_cast DESC;
