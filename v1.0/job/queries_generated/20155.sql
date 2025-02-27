WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS title_rank,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_titles
    FROM 
        aka_title AS mt
    JOIN 
        movie_keyword AS mk ON mt.id = mk.movie_id
    WHERE 
        mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%')
),
ActorsWithRoles AS (
    SELECT 
        a.id AS actor_id,
        an.name AS actor_name,
        ci.movie_id,
        ct.kind AS role_type,
        COALESCE(NULLIF(ci.note, ''), 'No note') AS role_note
    FROM 
        cast_info AS ci
    JOIN 
        aka_name AS an ON ci.person_id = an.person_id
    JOIN 
        comp_cast_type AS ct ON ci.person_role_id = ct.id
    WHERE 
        an.name IS NOT NULL
),
MoviesWithCast AS (
    SELECT 
        rm.movie_id,
        rm.title,
        ARRAY_AGG(DISTINCT awr.actor_name) AS actors,
        rm.production_year,
        rm.title_rank,
        rm.total_titles,
        COUNT(aw.role_type) AS role_count,
        CASE 
            WHEN COUNT(aw.role_type) = 0 THEN 'No roles cast'
            ELSE 'Roles present'
        END AS role_status
    FROM 
        RankedMovies AS rm
    LEFT JOIN 
        ActorsWithRoles AS aw ON rm.movie_id = aw.movie_id
    WHERE 
        rm.title_rank <= 5 -- Only keep top 5 titles by rank per year
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, rm.title_rank, rm.total_titles
)
SELECT 
    m.title,
    m.production_year,
    m.role_count,
    m.role_status,
    STRING_AGG(m.actors, ', ') AS actors_list
FROM 
    MoviesWithCast AS m
WHERE 
    m.role_status = 'Roles present' 
    AND m.production_year > 2000
GROUP BY 
    m.title, m.production_year, m.role_count, m.role_status
ORDER BY 
    m.production_year DESC, m.role_count DESC;

-- Additional bizarre predicates and edge constructs
WITH MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mi.info AS movie_info,
        COALESCE(NULLIF(mi.note, ''), 'Unspecified note') AS note_status
    FROM 
        movie_info AS mi 
    JOIN 
        aka_title AS mt ON mi.movie_id = mt.id
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%budget%')
),
FinalResults AS (
    SELECT 
        mc.title,
        mi.movie_info,
        (SELECT COUNT(*) FROM complete_cast WHERE movie_id = mc.movie_id) AS complete_cast_count
    FROM 
        MoviesWithCast AS mc
    LEFT JOIN 
        MovieInfo AS mi ON mc.movie_id = mi.movie_id
    WHERE 
        (mi.note_status IS NOT NULL OR mc.role_status = 'No roles cast')
)
SELECT 
    fr.title,
    fr.movie_info,
    CASE 
        WHEN fr.complete_cast_count IS NULL THEN 'No complete cast info'
        ELSE 'Complete cast info available'
    END AS cast_status
FROM 
    FinalResults AS fr
WHERE 
    fr.movie_info IS NOT NULL
ORDER BY 
    fr.title ASC;
