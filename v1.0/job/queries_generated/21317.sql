WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_name.name AS actor_name,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.id ORDER BY aka_name.name) AS actor_rank
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_title,
        actor_name,
        production_year
    FROM 
        RankedMovies
    WHERE 
        actor_rank <= 3 AND
        production_year > 2000
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(DISTINCT keyword.id) AS keyword_count
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
MoviesWithKeywords AS (
    SELECT 
        fm.movie_title,
        fm.actor_name,
        fm.production_year,
        COALESCE(kc.keyword_count, 0) AS keyword_count
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        KeywordCount kc ON fm.movie_title = (SELECT title FROM title WHERE id = fm.production_year) -- Assuming title id is used for production year for odd join
),
FinalResults AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        keyword_count,
        CASE 
            WHEN keyword_count > 5 THEN 'Highly Tagged'
            WHEN keyword_count BETWEEN 3 AND 5 THEN 'Moderately Tagged'
            ELSE 'Sparsely Tagged'
        END AS tag_level
    FROM 
        MoviesWithKeywords
    WHERE 
        production_year IS NOT NULL
)
SELECT 
    actor_name,
    movie_title,
    production_year,
    keyword_count,
    tag_level
FROM 
    FinalResults
WHERE 
    (tag_level = 'Highly Tagged' OR keyword_count IS NULL)
ORDER BY 
    production_year DESC, 
    actor_name;

-- Using an outer join to illustrate NULL logic 
SELECT 
    title.title AS Movie,
    aka_name.name AS Actor,
    movie_info.info AS Additional_Info
FROM 
    title
LEFT OUTER JOIN 
    cast_info ON title.id = cast_info.movie_id
LEFT OUTER JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
LEFT OUTER JOIN 
    movie_info ON title.id = movie_info.movie_id AND movie_info.info_type_id = 1
WHERE 
    title.production_year IS NOT NULL
ORDER BY 
    title.production_year DESC,
    aka_name.name;

-- An example of a correlated subquery to get the most recent movie per actor
SELECT 
    a.name AS Actor,
    (SELECT 
         t.title
     FROM 
         title t
     JOIN 
         cast_info ci ON t.id = ci.movie_id
     WHERE 
         ci.person_id = a.person_id
     ORDER BY 
         t.production_year DESC
     LIMIT 1) AS Most_Recent_Movie
FROM 
    aka_name a
WHERE 
    a.name IS NOT NULL
ORDER BY 
    a.name;
