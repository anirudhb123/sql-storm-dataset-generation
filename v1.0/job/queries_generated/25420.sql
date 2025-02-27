WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ARRAY_AGG(DISTINCT ak.name) AS alternate_names,
        ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON cc.subject_id = ci.id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        mt.id
),

TopMovies AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
)

SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.alternate_names,
    tm.keywords,
    tm.cast_count,
    COALESCE(STRING_AGG(DISTINCT char.name, ', '), 'No Characters') AS characters,
    COALESCE(STRING_AGG(DISTINCT r.role, ', '), 'No Roles') AS roles
FROM 
    TopMovies tm
LEFT JOIN 
    complete_cast cc ON tm.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.id
LEFT JOIN 
    char_name char ON ci.person_role_id = char.id
LEFT JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    tm.movie_rank <= 10
GROUP BY 
    tm.movie_id, tm.title, tm.production_year, tm.alternate_names, tm.keywords, tm.cast_count
ORDER BY 
    tm.cast_count DESC;

This SQL query performs the following tasks:

1. **Common Table Expression (CTE) `RankedMovies`:**
   - It selects movies with their associated alternate names and keywords.
   - It counts the number of distinct cast members for each movie.

2. **CTE `TopMovies`:**
   - It ranks these movies based on the number of cast members.

3. **Final Selection:**
   - It retrieves the top 10 movies from the `TopMovies` CTE.
   - It gathers associated character names and roles from other related tables.

4. **Output Structure:**
   - For each movie, it displays the movie id, title, production year, alternate titles, keywords, count of cast members, character names, and roles.

This query is designed to benchmark string processing capabilities by leveraging various text fields and aggregate functions.
