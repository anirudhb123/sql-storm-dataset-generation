WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(c.person_id) DESC) AS rn
    FROM 
        aka_title at
    JOIN 
        cast_info c ON at.id = c.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        tm.title,
        tm.production_year,
        GROUP_CONCAT(DISTINCT ak.name) AS actor_names,
        GROUP_CONCAT(DISTINCT cn.name) AS company_names,
        COALESCE(SUM(mi.info_type_id), 0) AS info_type_count
    FROM 
        TopMovies tm
    LEFT JOIN 
        complete_cast cc ON tm.title = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = tm.production_year
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        movie_info mi ON tm.production_year = mi.movie_id
    GROUP BY 
        tm.title, tm.production_year
)
SELECT 
    title,
    production_year,
    actor_names,
    company_names,
    info_type_count
FROM 
    MovieDetails
WHERE 
    info_type_count > 5
ORDER BY 
    production_year DESC, title;
