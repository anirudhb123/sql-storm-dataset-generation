WITH NameCounts AS (
    SELECT 
        ak.person_id,
        COUNT(DISTINCT ak.name) AS num_aliases,
        STRING_AGG(DISTINCT ak.name, ', ') AS all_aliases
    FROM 
        aka_name ak
    GROUP BY 
        ak.person_id
),
MovieTitleCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT mt.title) AS num_movies,
        STRING_AGG(DISTINCT mt.title, '; ') AS all_movies
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        aka_title mt ON mt.movie_id = c.movie_id
    GROUP BY 
        c.person_id
),
PersonInfo AS (
    SELECT 
        pi.person_id,
        STRING_AGG(DISTINCT pi.info, '; ') AS all_info
    FROM 
        person_info pi
    GROUP BY 
        pi.person_id
),
FinalBenchmark AS (
    SELECT 
        n.name AS person_name,
        nc.num_aliases,
        nc.all_aliases,
        mc.num_movies,
        mc.all_movies,
        pi.all_info
    FROM 
        NameCounts nc
    JOIN 
        Name n ON n.id = nc.person_id
    LEFT JOIN 
        MovieTitleCounts mc ON mc.person_id = nc.person_id
    LEFT JOIN 
        PersonInfo pi ON pi.person_id = nc.person_id
)
SELECT 
    person_name,
    num_aliases,
    all_aliases,
    num_movies,
    all_movies,
    all_info
FROM 
    FinalBenchmark
WHERE 
    num_movies > 5
ORDER BY 
    num_aliases DESC, num_movies DESC;
