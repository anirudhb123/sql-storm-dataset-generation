WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actors,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = at.id
    GROUP BY 
        at.id, at.title, at.production_year
),
TopMovies AS (
    SELECT 
        title,
        production_year,
        cast_count,
        actors,
        keywords,
        ROW_NUMBER() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    tm.title,
    tm.production_year,
    tm.cast_count,
    tm.actors,
    tm.keywords
FROM 
    TopMovies tm
WHERE 
    tm.rank <= 10
ORDER BY 
    tm.production_year DESC, tm.cast_count DESC;

This SQL query accomplishes several tasks:
1. It ranks movies based on the number of distinct actors (cast count) associated with each movie title in the `aka_title` table.
2. It aggregates actor names and keywords related to each movie to provide additional context.
3. It uses Common Table Expressions (CTEs) to structure the logic, making it readable.
4. Finally, it selects the top 10 movies with the highest cast count, ordered by production year and then by the number of cast members, providing a rich insight into popular movies that have a substantial cast.
