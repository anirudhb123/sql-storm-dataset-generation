
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS actor_count,
        LISTAGG(DISTINCT CONCAT(a.name, ' as ', r.role), ', ') WITHIN GROUP (ORDER BY a.name) AS roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id 
    JOIN 
        role_type r ON c.role_id = r.id
    GROUP BY 
        c.movie_id
),
MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(ar.actor_count, 0) AS actor_count,
        ar.roles,
        COALESCE(mi.info, 'No information') AS movie_info,
        CASE 
            WHEN ar.actor_count > 5 THEN 'Blockbuster'
            WHEN ar.actor_count > 0 THEN 'Indie'
            ELSE 'No cast'
        END AS movie_type
    FROM 
        aka_title m
    LEFT JOIN 
        ActorRoles ar ON m.id = ar.movie_id
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        md.actor_count,
        md.roles,
        md.movie_info,
        md.movie_type
    FROM 
        RankedMovies rm
    LEFT JOIN 
        MovieDetails md ON rm.movie_id = md.movie_id
    WHERE 
        rm.title_rank <= 5
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.roles,
    fr.movie_info,
    fr.movie_type
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.title;
