WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rn
    FROM 
        aka_title t
    WHERE 
        t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
),
TopMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year
    FROM 
        RankedMovies rm
    WHERE 
        rm.rn <= 10
),
MovieDetails AS (
    SELECT 
        tm.movie_id,
        tm.title,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        MAX(mi.info) AS keyword_info
    FROM 
        TopMovies tm
    LEFT JOIN 
        movie_companies mc ON tm.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON cc.movie_id = tm.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = tm.movie_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = tm.movie_id
    LEFT JOIN 
        keyword k ON k.id = mk.keyword_id
    LEFT JOIN 
        movie_info mi ON mi.movie_id = tm.movie_id
    GROUP BY 
        tm.movie_id, tm.title
),
FinalResults AS (
    SELECT 
        md.*,
        CASE 
            WHEN total_cast > 0 THEN 'Has Cast'
            ELSE 'No Cast'
        END AS cast_status,
        COALESCE(keyword_info, 'No Keywords') AS keywords
    FROM 
        MovieDetails md
)

SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.company_names,
    fr.total_cast,
    fr.cast_status,
    fr.keywords
FROM 
    FinalResults fr
WHERE 
    fr.production_year >= 2000
ORDER BY 
    fr.production_year DESC, 
    fr.title ASC;
