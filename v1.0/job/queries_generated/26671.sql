WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actors_list,
        AVG(CASE WHEN m.info_type_id = 1 THEN CAST(m.info AS FLOAT) END) AS average_rating
    FROM 
        title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_info m ON t.id = m.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
TopRatedMovies AS (
    SELECT 
        rm.*,
        RANK() OVER (ORDER BY rm.average_rating DESC NULLS LAST) AS rank
    FROM 
        RankedMovies rm
)
SELECT 
    tr.movie_id,
    tr.title,
    tr.production_year,
    tr.cast_count,
    tr.actors_list,
    tr.average_rating
FROM 
    TopRatedMovies tr
WHERE 
    tr.rank <= 10
ORDER BY 
    tr.average_rating DESC;

This query generates a list of the top 10 movies with the highest average ratings, along with the total number of cast members and a concatenated list of actor names. It utilizes Common Table Expressions (CTEs) for clarity, aggregates string processing with `STRING_AGG`, and ranks the results based on average ratings.
