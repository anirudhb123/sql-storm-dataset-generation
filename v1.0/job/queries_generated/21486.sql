WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.kind_id ORDER BY t.production_year DESC) AS rank_within_kind
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
TopRatedMovies AS (
    SELECT 
        movie_id, 
        AVG(info_text.rating) AS avg_rating
    FROM (
        SELECT 
            m.movie_id, 
            mi.info AS rating
        FROM 
            movie_info mi
        JOIN 
            movie_info_idx midi ON mi.movie_id = midi.movie_id 
        WHERE 
            mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    ) info_text GROUP BY movie_id
),
NullSafeMovieReviews AS (
    SELECT 
        title_id,
        COALESCE(tr.avg_rating, 0) AS average_rating,
        CASE 
            WHEN COALESCE(tr.avg_rating, 0) > 7 THEN 'Highly Rated'
            WHEN COALESCE(tr.avg_rating, 0) BETWEEN 4 AND 7 THEN 'Moderately Rated'
            ELSE 'Poorly Rated'
        END AS rating_category
    FROM 
        RankedMovies rm
    LEFT OUTER JOIN 
        TopRatedMovies tr ON rm.title_id = tr.movie_id
),
PersonMovieRoles AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        p.name,
        rt.role,
        ROW_NUMBER() OVER (PARTITION BY ca.person_id ORDER BY ca.nr_order) AS role_order
    FROM 
        cast_info ca
    JOIN 
        aka_name p ON ca.person_id = p.person_id
    LEFT JOIN 
        role_type rt ON ca.role_id = rt.id
)
SELECT 
    nm.title, 
    nmr.average_rating,
    nmr.rating_category,
    pm.name AS actor_name,
    pm.role,
    pm.role_order,
    CASE 
        WHEN nmr.average_rating IS NULL THEN 'No Ratings'
        ELSE 'Some Ratings'
    END AS rating_status
FROM 
    NullSafeMovieReviews nmr
JOIN 
    movie_companies mc ON mc.movie_id = nmr.title_id
JOIN 
    PersonMovieRoles pm ON pm.movie_id = nmr.title_id
WHERE 
    nmr.rating_category = 'Highly Rated'
    AND mc.company_id IN (SELECT id FROM company_name WHERE country_code = 'USA')
ORDER BY 
    nmr.average_rating DESC,
    pm.role_order ASC
LIMIT 100;

Here’s a breakdown of the query:

1. **Common Table Expressions (CTEs)**:
   - `RankedMovies`: Ranks movies within their kind by production year.
   - `TopRatedMovies`: Calculates the average rating for each movie.
   - `NullSafeMovieReviews`: Combines average ratings and categorizes the ratings safely handling NULLs.
   - `PersonMovieRoles`: Retrieves actors and their roles for all movies in the result sets.

2. **Outer Join**: Utilized in `NullSafeMovieReviews` to ensure that all movies are preserved regardless of whether they have ratings.

3. **Window Functions**: Employed to rank movies and to order roles for actors with `ROW_NUMBER()`.

4. **COALESCE & CASE Statements**: Used for NULL handling and creating custom rating categories from movie ratings.

5. **Subquery for IN Clause**: Filters companies based on a specific country code.

6. **ORDER BY and LIMIT**: Orders the final results by average ratings and role order, limiting the output to 100 records.

This query captures a significant part of the schema while also demonstrating advanced SQL techniques, making it suitable for performance benchmarking.
