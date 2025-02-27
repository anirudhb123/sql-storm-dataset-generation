WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        title t
),
PopularMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title_id,
        COUNT(DISTINCT c.person_id) AS cast_count
    FROM 
        complete_cast m
    JOIN 
        movie_companies mc ON m.movie_id = mc.movie_id
    JOIN 
        cast_info c ON m.movie_id = c.movie_id
    GROUP BY 
        m.id, m.title_id
    HAVING 
        COUNT(DISTINCT c.person_id) > 5
),
MovieLinks AS (
    SELECT 
        ml.movie_id, 
        ml.linked_movie_id, 
        lt.link AS link_type
    FROM 
        movie_link ml
    JOIN 
        link_type lt ON ml.link_type_id = lt.id
),
TitleWithLinks AS (
    SELECT 
        rt.title,
        rt.production_year,
        ml.linked_movie_id,
        ml.link_type
    FROM 
        RankedTitles rt
    JOIN 
        MovieLinks ml ON rt.title_id = ml.movie_id
),
PersonInfo AS (
    SELECT 
        pi.person_id,
        pi.info
    FROM 
        person_info pi
    JOIN 
        aka_name an ON pi.person_id = an.person_id
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    COUNT(DISTINCT p.person_id) AS Unique_Actors,
    STRING_AGG(DISTINCT pi.info, ', ') AS Actor_Info,
    GROUP_CONCAT(DISTINCT tl.link_type || ': ' || tl.linked_movie_id) AS Related_Movies
FROM 
    TitleWithLinks t
JOIN 
    PopularMovies pm ON t.movie_id = pm.movie_id
JOIN 
    cast_info c ON pm.movie_id = c.movie_id
JOIN 
    aka_name an ON c.person_id = an.person_id
JOIN 
    PersonInfo pi ON pi.person_id = c.person_id
JOIN 
    MovieLinks ml ON pm.movie_id = ml.movie_id
GROUP BY 
    t.title, t.production_year
ORDER BY 
    t.production_year DESC, Unique_Actors DESC;
