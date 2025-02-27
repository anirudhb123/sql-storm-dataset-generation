WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COUNT(*) DESC) AS rank_by_cast_count
    FROM
        aka_title a
    INNER JOIN
        cast_info c ON a.id = c.movie_id
    GROUP BY
        a.id, a.title, a.production_year
),
FilteredMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank_by_cast_count <= 5
),
Companies AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type,
        COUNT(*) AS num_movies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id, cn.name, ct.kind
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS movie_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    fm.title,
    fm.production_year,
    COALESCE(ci.company_name, 'Independent') AS company_name,
    COALESCE(mi.movie_info, 'No Info') AS movie_info,
    ROW_NUMBER() OVER (ORDER BY fm.production_year DESC) AS row_num
FROM 
    FilteredMovies fm
LEFT JOIN 
    Companies ci ON fm.movie_id = ci.movie_id
LEFT JOIN 
    MovieInfo mi ON fm.movie_id = mi.movie_id
WHERE 
    EXISTS (SELECT 1 FROM movie_keyword mk WHERE mk.movie_id = fm.movie_id AND mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE 'Action%'))
ORDER BY 
    fm.production_year DESC, fm.title;
