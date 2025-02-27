WITH Recursive CastHierarchy AS (
    SELECT 
        ci movie_id,
        ci.person_id,
        ct.kind AS role_type,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    WHERE 
        ct.kind IS NOT NULL

    UNION ALL

    SELECT 
        ci.movie_id,
        ci.person_id,
        ct.kind AS role_type,
        ch.level + 1
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    JOIN 
        CastHierarchy ch ON ci.movie_id = ch.movie_id
    WHERE 
        ch.role_type = 'Supporting'
),
MovieDetails AS (
    SELECT 
        mt.title AS movie_title,
        mt.production_year,
        COUNT(DISTINCT ch.person_id) AS total_cast,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        MAX(CASE WHEN mt.production_year < 2000 THEN 'Classic' ELSE 'Modern' END) AS era,
        COUNT(DISTINCT mk.keyword) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.movie_id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON mt.movie_id = mk.movie_id
    GROUP BY 
        mt.title, mt.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        total_cast,
        cast_names,
        keyword_count,
        ROW_NUMBER() OVER (PARTITION BY era ORDER BY total_cast DESC) AS movie_rank
    FROM 
        MovieDetails
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    tm.keyword_count,
    CASE 
        WHEN tm.movie_rank <= 5 THEN 'Top 5'
        ELSE 'Other'
    END AS rank_category
FROM 
    TopMovies tm
WHERE 
    tm.movie_rank <= 5 OR tm.keyword_count > 10
ORDER BY 
    production_year DESC,
    rank_category,
    total_cast DESC;
