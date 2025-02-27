WITH RECURSIVE ActorRoles AS (
    SELECT 
        ci.person_id,
        ct.kind AS role_name,
        COUNT(*) AS total_movies
    FROM 
        cast_info ci
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
    GROUP BY 
        ci.person_id, ct.kind
),
TopActors AS (
    SELECT 
        ar.person_id,
        SUM(ar.total_movies) AS total_movies_by_person
    FROM 
        ActorRoles ar
    GROUP BY 
        ar.person_id
    HAVING 
        SUM(ar.total_movies) > 5
),
RecentMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(kw.keyword, 'No Keyword') AS keyword
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        m.production_year > 2020
),
ActorMovieInfo AS (
    SELECT 
        p.person_id,
        a.name,
        rm.movie_id,
        rm.title,
        rm.production_year,
        ROW_NUMBER() OVER (PARTITION BY p.person_id ORDER BY rm.production_year DESC) AS rn
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    JOIN 
        RecentMovies rm ON ci.movie_id = rm.movie_id
    WHERE 
        p.person_id IN (SELECT person_id FROM TopActors)
)
SELECT 
    ami.person_id,
    ami.name,
    ami.title,
    ami.production_year,
    (SELECT COUNT(*) FROM movie_info mi WHERE mi.movie_id = ami.movie_id AND mi.info_type_id = 1) AS info_count, -- assuming info_type_id = 1 is 'Synopsis'
    STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords
FROM 
    ActorMovieInfo ami
LEFT JOIN 
    movie_keyword mk ON ami.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    ami.rn <= 3
GROUP BY 
    ami.person_id, ami.name, ami.title, ami.production_year
ORDER BY 
    ami.person_id, ami.production_year DESC;

This SQL query uses several advanced features:

1. **Recursive CTE**: `ActorRoles` collects actor roles and their movie counts.
2. **Aggregates and GROUP BY**: Aggregates over actors and groups results.
3. **LEFT JOIN**: Used in `RecentMovies` to handle cases where movies may not have keywords.
4. **Row Number Window Function**: Ranks movies for each actor by their production year.
5. **String Aggregation**: Combines keywords for the returning dataset.
6. **NULL Logic**: Uses `COALESCE` to handle cases where no keywords are found.
7. **Subqueries**: Finds additional data through nested selects.

The query ultimately returns a summary of top actors based on their roles and the movies they've been in post-2020, including counts of specific movie info and a list of associated keywords.
