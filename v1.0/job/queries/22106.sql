WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY aa.name) AS rn,
        COUNT(*) OVER (PARTITION BY a.production_year) AS total_movies
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_name aa ON aa.person_id = a.id
    WHERE 
        k.keyword LIKE '%action%' 
        AND a.production_year IS NOT NULL
)
, MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
        STRING_AGG(DISTINCT ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
, GenreStats AS (
    SELECT 
        a.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS genre_count,
        AVG(CASE 
            WHEN k.phonetic_code IS NOT NULL THEN 1
            ELSE 0
        END) AS avg_with_phonetic
    FROM 
        aka_title a
    LEFT JOIN 
        movie_keyword mk ON a.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        a.movie_id
)
SELECT 
    RM.movie_id,
    RM.title,
    RM.production_year,
    COALESCE(MC.company_names, 'No Companies') AS company_names,
    COALESCE(MC.company_types, 'No Types') AS company_types,
    GS.genre_count,
    GS.avg_with_phonetic
FROM 
    RankedMovies RM
LEFT JOIN 
    MovieCompanies MC ON RM.movie_id = MC.movie_id
LEFT JOIN 
    GenreStats GS ON RM.movie_id = GS.movie_id
WHERE 
    RM.rn <= 5 
ORDER BY 
    RM.production_year DESC, RM.title;