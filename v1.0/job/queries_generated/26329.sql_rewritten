WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT mc.company_id) AS company_count,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT mc.company_id) DESC) AS rank
    FROM 
        aka_title mt
    JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

TopMovies AS (
    SELECT 
        movie_id,
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),

CastDetails AS (
    SELECT 
        ak.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        cc.note AS cast_note,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS role_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info cc ON ak.person_id = cc.person_id
    JOIN 
        aka_title at ON cc.movie_id = at.id
    JOIN 
        TopMovies tm ON at.id = tm.movie_id
)

SELECT 
    cd.actor_name,
    cd.movie_title,
    cd.production_year,
    cd.cast_note
FROM 
    CastDetails cd
WHERE 
    cd.role_rank = 1
ORDER BY 
    cd.production_year DESC;