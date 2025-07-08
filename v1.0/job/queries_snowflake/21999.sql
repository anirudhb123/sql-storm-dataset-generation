
WITH RecursiveActorRoles AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        ct.kind AS role_type,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY ct.kind) AS role_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
),

MovieDetails AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        ARRAY_AGG(DISTINCT ak.name) AS actor_names
    FROM 
        aka_title mt
    LEFT JOIN 
        cast_info ci ON mt.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
),

RankedMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.total_actors,
        md.actor_names,
        RANK() OVER (ORDER BY md.total_actors DESC, md.production_year ASC) AS rank_by_actors
    FROM 
        MovieDetails md
    WHERE 
        md.total_actors > 0 
),

FilteredMovies AS (
    SELECT 
        rm.*,
        CASE 
            WHEN rm.production_year >= 2000 THEN 'Modern'
            ELSE 'Classic'
        END AS era
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_actors <= 10 
)

SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.total_actors,
    fm.actor_names,
    fm.era,
    (SELECT AVG(CASE WHEN ci.note IS NULL THEN 0 ELSE 1 END) 
     FROM cast_info ci 
     WHERE ci.movie_id = fm.movie_id) AS avg_actor_notes,
    LISTAGG(DISTINCT ki.keyword, ', ') WITHIN GROUP (ORDER BY ki.keyword) AS keywords
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_keyword mk ON fm.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
GROUP BY 
    fm.movie_id, fm.title, fm.production_year, fm.total_actors, fm.actor_names, fm.era, fm.rank_by_actors
HAVING 
    COUNT(DISTINCT ki.id) > 2 
ORDER BY 
    fm.rank_by_actors, fm.production_year DESC;
