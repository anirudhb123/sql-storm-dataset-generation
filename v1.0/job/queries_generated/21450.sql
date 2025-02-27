WITH RankedMovies AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_per_year
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorMovieInfo AS (
    SELECT 
        c.movie_id, 
        ak.name AS actor_name, 
        ct.kind AS role, 
        COUNT(c.id) OVER (PARTITION BY c.movie_id) AS actor_count,
        MAX(CASE WHEN pi.info_type_id = (SELECT id FROM info_type WHERE info = 'birth date') THEN pi.info END) AS actor_birth_date
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    JOIN 
        role_type ct ON c.role_id = ct.id
    LEFT JOIN 
        person_info pi ON c.person_id = pi.person_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MoviesWithActorInfo AS (
    SELECT 
        rm.title_id, 
        rm.title, 
        rm.production_year,
        ami.actor_name, 
        ami.role, 
        ami.actor_birth_date, 
        mk.keywords,
        ami.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovieInfo ami ON rm.title_id = ami.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.title_id = mk.movie_id
)

SELECT 
    m.title, 
    m.production_year, 
    STRING_AGG(DISTINCT m.actor_name, '; ') AS actor_names,
    MAX(CASE WHEN m.role IS NOT NULL THEN m.role ELSE 'Unknown Role' END) AS primary_role,
    COUNT(DISTINCT m.actor_name) AS total_actors,
    COALESCE(m.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN m.actor_birth_date IS NOT NULL THEN
            FROM_UNIXTIME(UNIX_TIMESTAMP(m.actor_birth_date, 'yyyy-MM-dd'), 'yyyy-MM-dd')
        ELSE 
            'Unknown Birth Date' 
    END AS formatted_birth_date
FROM 
    MoviesWithActorInfo m
WHERE 
    m.production_year > 2000
GROUP BY 
    m.title, m.production_year
HAVING 
    COUNT(DISTINCT m.actor_name) > 1
ORDER BY 
    m.production_year DESC, 
    m.title ASC;

The SQL query does the following:
1. It utilizes Common Table Expressions (CTEs) to rank movies by production year and gather actor-related information.
2. It incorporates window functions for counting actors per movie.
3. The outer join is performed when combining movie data, actor info, and keywords.
4. It applies complex predicates, including checking for `NULL` values and formatting the birth date.
5. The query aggregates information, using `STRING_AGG` to consolidate actor names and keywords.
6. It filters for movies produced after 2000 while ensuring there are at least two distinct actors.
7. Results are ordered by production year and title.
