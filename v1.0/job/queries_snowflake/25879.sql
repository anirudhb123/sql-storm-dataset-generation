
WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        LISTAGG(DISTINCT ak.name, ', ') AS aka_names,
        LISTAGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        aka_name ak ON cc.subject_id = ak.person_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id, mt.title, mt.production_year
),
RankedRoles AS (
    SELECT 
        cc.movie_id,
        LISTAGG(DISTINCT rt.role, ', ') AS roles,
        COUNT(DISTINCT cc.person_id) AS cast_count
    FROM 
        cast_info cc
    JOIN 
        role_type rt ON cc.role_id = rt.id
    GROUP BY 
        cc.movie_id
),
FinalRanking AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.aka_names,
        rr.roles,
        rr.cast_count,
        ROW_NUMBER() OVER (ORDER BY rm.production_year DESC, rr.cast_count DESC) AS rank
    FROM 
        RankedMovies rm
    LEFT JOIN 
        RankedRoles rr ON rm.movie_id = rr.movie_id
)
SELECT 
    movie_id,
    title,
    production_year,
    aka_names,
    roles,
    cast_count,
    rank
FROM 
    FinalRanking
WHERE 
    rank <= 50
ORDER BY 
    rank;
