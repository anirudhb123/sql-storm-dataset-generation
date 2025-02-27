WITH RankedTitles AS (
    SELECT 
        a.title,
        t.production_year,
        t.kind_id,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY LENGTH(a.title) DESC) AS title_rank
    FROM 
        aka_title a
    JOIN 
        title t ON a.movie_id = t.id
    WHERE 
        t.production_year >= 2000
),
TopTitles AS (
    SELECT 
        title,
        production_year,
        kind_id
    FROM 
        RankedTitles
    WHERE 
        title_rank <= 5
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        c.movie_id,
        COUNT(c.id) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        ak.name, c.movie_id
),
MoviesWithActors AS (
    SELECT 
        tt.title,
        tt.production_year,
        tt.kind_id,
        ad.actor_name,
        ad.role_count
    FROM 
        TopTitles tt
    JOIN 
        ActorDetails ad ON tt.id = ad.movie_id
)
SELECT 
    mwa.title,
    mwa.production_year,
    kt.kind,
    mwa.actor_name,
    mwa.role_count
FROM 
    MoviesWithActors mwa
JOIN 
    kind_type kt ON mwa.kind_id = kt.id
ORDER BY 
    mwa.production_year DESC, 
    LENGTH(mwa.title), 
    mwa.role_count DESC;

This query benchmarks string processing by:

1. Extracting titles from the `aka_title` and `title` tables that are produced from 2000 onwards.
2. Ranking them based on title length.
3. Selecting the top 5 longest titles per production year.
4. Joining the ranked titles with the `cast_info` and `aka_name` tables to calculate the number of roles for each actor in those selected movies.
5. Finally, it retrieves the relevant actor details along with their movie titles and sorts the results by production year, title length, and role count.

This query touches upon multiple string manipulation aspects such as ranking, length evaluation, and ordering based on strings, making it suitable for benchmarking string processing in SQL.
