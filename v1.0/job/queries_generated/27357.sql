WITH RankedTitles AS (
    SELECT 
        at.id AS title_id,
        at.title,
        at.production_year,
        at.kind_id,
        at.imdb_index,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY LENGTH(at.title) DESC) AS title_rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        a.name AS actor_name,
        at.title AS movie_title,
        at.production_year,
        GROUP_CONCAT(DISTINCT a1.name ORDER BY a1.name) AS co_actors,
        COUNT(DISTINCT c.person_id) AS total_cast_members,
        SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        RankedTitles at ON c.movie_id = at.title_id
    JOIN 
        cast_info c2 ON c.movie_id = c2.movie_id AND c.person_id != c2.person_id
    LEFT JOIN 
        aka_name a1 ON c2.person_id = a1.person_id
    GROUP BY 
        a.name, at.title, at.production_year
),
FilteredMovies AS (
    SELECT 
        am.actor_name,
        am.movie_title,
        am.production_year,
        am.co_actors,
        am.total_cast_members,
        am.notes_count
    FROM 
        ActorMovieInfo am
    WHERE 
        am.total_cast_members > 3
)
SELECT 
    fm.actor_name,
    fm.movie_title,
    fm.production_year,
    fm.co_actors,
    fm.total_cast_members,
    fm.notes_count,
    ct.kind AS company_type,
    ci.info AS additional_info
FROM 
    FilteredMovies fm
LEFT JOIN 
    movie_companies mc ON fm.movie_title = mc.movie_id
LEFT JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_info mi ON fm.movie_title = mi.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
WHERE 
    note LIKE '%award%'
ORDER BY 
    fm.production_year DESC, 
    fm.total_cast_members DESC;
