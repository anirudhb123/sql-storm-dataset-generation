WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER(PARTITION BY mt.production_year ORDER BY mt.production_year DESC, mt.title) AS year_rank,
        COUNT(DISTINCT mk.keyword_id) OVER(PARTITION BY mt.id) AS keyword_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    WHERE 
        mt.production_year IS NOT NULL
),
TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year,
        keyword_count
    FROM 
        RankedMovies 
    WHERE 
        year_rank <= 5
),
ExpandedCast AS (
    SELECT 
        c.movie_id,
        STRING_AGG(CONCAT(a.name, ' (', rt.role, ')'), ', ') AS cast_list,
        COUNT(c.id) AS cast_member_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type rt ON c.role_id = rt.id
    GROUP BY 
        c.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ec.cast_list,
    ec.cast_member_count,
    COALESCE((SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = tm.movie_id), 0) AS company_count,
    NULLIF((SELECT MIN(mi.info) FROM movie_info mi WHERE mi.movie_id = tm.movie_id AND mi.info_type_id IN (SELECT id FROM info_type WHERE info= 'Awards')), '') AS awards_info
FROM 
    TopMovies tm
LEFT JOIN 
    ExpandedCast ec ON tm.movie_id = ec.movie_id
ORDER BY 
    tm.production_year DESC,
    tm.keyword_count DESC,
    tm.title;
