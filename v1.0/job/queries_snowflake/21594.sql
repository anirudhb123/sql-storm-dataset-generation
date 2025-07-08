
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rn,
        COUNT(*) OVER (PARTITION BY t.production_year) AS total_movies
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        LISTAGG(DISTINCT a.name, ', ') WITHIN GROUP (ORDER BY a.name) AS actors_list,
        COUNT(ci.person_id) AS actor_count,
        AVG(CASE 
                WHEN ci.note IS NULL THEN 0 
                ELSE LENGTH(ci.note) 
            END) AS avg_note_length
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS production_companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    WHERE 
        mc.note IS NOT NULL
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    cd.actors_list,
    cd.actor_count,
    ci.production_companies,
    rm.total_movies,
    CASE 
        WHEN cd.actor_count = 0 THEN 'No actors' 
        ELSE 'Has actors' 
    END AS actor_status,
    EXISTS (
        SELECT 1 
        FROM movie_info mi 
        WHERE mi.movie_id = rm.movie_id 
        AND mi.info_type_id IN (
            SELECT it.id 
            FROM info_type it 
            WHERE it.info ILIKE '%critics%'
        )
    ) AS has_critics_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    CompanyInfo ci ON rm.movie_id = ci.movie_id
WHERE 
    rm.rn = 1 
ORDER BY 
    rm.production_year, rm.title;
