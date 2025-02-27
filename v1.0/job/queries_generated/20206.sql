WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),

FilteredCast AS (
    SELECT 
        c.movie_id,
        c.person_id,
        COALESCE(cc.kind, 'UNKNOWN') AS role_name,
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS cast_count
    FROM 
        cast_info c
    LEFT JOIN 
        comp_cast_type cc ON c.person_role_id = cc.id
    WHERE 
        c.note IS NULL AND -- filtering out notes that might contain irrelevant comments
        c.nr_order IS NOT NULL
),

MovieWithActors AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        fc.person_id,
        COUNT(fc.id) OVER (PARTITION BY rm.movie_id) AS actor_count,
        SUM(CASE WHEN fc.role_name = 'Lead' THEN 1 ELSE 0 END) AS lead_actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        FilteredCast fc ON rm.movie_id = fc.movie_id
)

SELECT 
    mwa.movie_id,
    mwa.title,
    mwa.production_year,
    mwa.actor_count,
    mwa.lead_actor_count,
    COALESCE(a.name, 'NO NAME') AS actor_name,
    CASE
        WHEN mwa.actor_count >= 5 THEN 'Blockbuster'
        WHEN mwa.lead_actor_count > 0 THEN 'Featured'
        ELSE 'Indie'
    END AS movie_type
FROM 
    MovieWithActors mwa
LEFT JOIN 
    aka_name a ON mwa.person_id = a.person_id
WHERE 
    mwa.movie_id IN (
        SELECT movie_id 
        FROM movie_info 
        WHERE info_type_id IN (SELECT id FROM info_type WHERE info ILIKE '%Best%')
    )
    AND mw.actor_count IS NOT NULL
ORDER BY 
    mwa.production_year DESC, 
    mwa.actor_count DESC
LIMIT 100;
