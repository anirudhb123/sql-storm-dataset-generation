
WITH RankedTitles AS (
    SELECT 
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
TopTitles AS (
    SELECT 
        title, 
        production_year 
    FROM 
        RankedTitles 
    WHERE 
        rn <= 5
),
MovieDetails AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        COALESCE(mc.company_name, 'Unknown') AS company_name,
        mt.production_year
    FROM 
        title mt
    LEFT JOIN (
        SELECT 
            movie_id,
            LISTAGG(cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_name
        FROM 
            movie_companies mc
        JOIN 
            company_name cn ON mc.company_id = cn.id 
        WHERE 
            mc.company_type_id IN (SELECT id FROM company_type WHERE kind = 'Distributor')
        GROUP BY 
            movie_id
    ) mc ON mt.id = mc.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        md.movie_id, 
        md.title, 
        md.company_name, 
        md.production_year, 
        COALESCE(cd.actor_count, 0) AS actor_count
    FROM 
        MovieDetails md
    LEFT JOIN 
        CastDetails cd ON md.movie_id = cd.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.company_name,
    mi.actor_count,
    CASE 
        WHEN mi.actor_count > 5 THEN 'Ensemble Cast'
        WHEN mi.actor_count = 0 THEN 'No Actors'
        ELSE 'Moderate Cast'
    END AS cast_type,
    (SELECT LISTAGG(name, ', ') WITHIN GROUP (ORDER BY name) 
     FROM aka_name an 
     WHERE an.person_id IN (
         SELECT ci.person_id 
         FROM cast_info ci 
         WHERE ci.movie_id = mi.movie_id 
         AND ci.note IS NULL
     )) AS main_actors
FROM 
    MovieInfo mi
JOIN 
    TopTitles tt ON mi.title = tt.title AND mi.production_year = tt.production_year
WHERE 
    mi.production_year > (SELECT MIN(production_year) FROM title)
ORDER BY 
    mi.production_year DESC, mi.actor_count DESC;
