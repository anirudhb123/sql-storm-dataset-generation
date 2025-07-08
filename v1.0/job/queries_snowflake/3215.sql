
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY RANDOM()) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCounts AS (
    SELECT 
        c.movie_id, 
        COUNT(c.person_id) AS cast_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
FavoriteActors AS (
    SELECT 
        ak.person_id,
        ak.name,
        COUNT(DISTINCT ci.movie_id) AS movie_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id 
    WHERE 
        rt.role LIKE '%star%'
    GROUP BY 
        ak.person_id, ak.name
    HAVING 
        COUNT(DISTINCT ci.movie_id) > 5
),
MovieCompanyInfo AS (
    SELECT 
        m.movie_id,
        LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
    FROM 
        movie_companies m
    JOIN 
        company_name cn ON m.company_id = cn.id
    GROUP BY 
        m.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(cc.cast_count, 0) AS total_cast,
    f.name AS favorite_actor,
    f.movie_count,
    mci.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    CastCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    FavoriteActors f ON f.movie_count > 5 
LEFT JOIN 
    MovieCompanyInfo mci ON mci.movie_id = rm.movie_id
WHERE 
    rm.rn <= 10 
ORDER BY 
    rm.production_year DESC, rm.movie_id;
