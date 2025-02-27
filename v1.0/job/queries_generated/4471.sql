WITH RankedMovies AS (
    SELECT 
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY b.nr_order) AS rank_order
    FROM 
        aka_title a
    JOIN 
        cast_info b ON a.id = b.movie_id
    WHERE 
        a.production_year >= 2000
), 
MovieDetails AS (
    SELECT 
        rm.title,
        rm.production_year,
        COALESCE(CL.name, 'Unknown') AS character_name,
        COALESCE(CT.kind, 'Unknown') AS company_type,
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) AS awards_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        complete_cast cc ON rm.title = cc.movie_id
    LEFT JOIN 
        char_name CL ON cc.subject_id = CL.id
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = rm.production_year
    LEFT JOIN 
        company_type CT ON mc.company_type_id = CT.id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = rm.production_year
    GROUP BY 
        rm.title, rm.production_year, CL.name, CT.kind
    HAVING 
        SUM(CASE WHEN mi.info_type_id = 1 THEN 1 ELSE 0 END) > 0
), 
TopMovies AS (
    SELECT 
        title,
        production_year,
        character_name,
        ROW_NUMBER() OVER (ORDER BY awards_count DESC) AS top_rank
    FROM 
        MovieDetails
    WHERE 
        character_name IS NOT NULL
)
SELECT 
    *
FROM 
    TopMovies
WHERE 
    top_rank <= 10
ORDER BY 
    production_year DESC, character_name;
