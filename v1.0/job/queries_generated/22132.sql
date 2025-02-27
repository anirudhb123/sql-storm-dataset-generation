WITH ranked_movies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(ci.person_id) AS cast_count,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank_in_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
), 

company_details AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type,
        ROW_NUMBER() OVER (PARTITION BY mc.movie_id ORDER BY c.name) AS company_rank
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 

exceptional_movies AS (
    SELECT 
        rm.movie_id, 
        rm.title, 
        rm.production_year,
        cd.company_name,
        cd.company_type,
        CASE 
            WHEN rm.cast_count > 10 THEN 'Blockbuster'
            WHEN rm.cast_count BETWEEN 5 AND 10 THEN 'Moderate'
            WHEN rm.cast_count < 5 THEN 'Indie'
            ELSE 'Unknown'
        END AS movie_category
    FROM 
        ranked_movies rm
    LEFT JOIN 
        company_details cd ON rm.movie_id = cd.movie_id 
    WHERE 
        rm.rank_in_year < 6     -- top 5 movies per year
        AND rm.production_year IS NOT NULL
)

SELECT 
    em.title,
    em.production_year,
    em.company_name,
    em.company_type,
    em.movie_category,
    CASE 
        WHEN em.company_type IS NULL THEN 'Not Associated' 
        ELSE 'Associated'
    END AS association_status,
    COALESCE(
        (SELECT STRING_AGG(DISTINCT k.keyword, ', ') 
         FROM movie_keyword mk 
         JOIN keyword k ON mk.keyword_id = k.id 
         WHERE mk.movie_id = em.movie_id), 
         'No Keywords') AS keywords
FROM 
    exceptional_movies em
ORDER BY 
    em.production_year DESC, 
    em.movie_category, 
    em.title;

This query does the following:

1. **Common Table Expressions (CTEs)**:
   - `ranked_movies`: Ranks movies based on the number of cast members per production year.
   - `company_details`: Joins companies associated with movies to retrieve their details while ranking them per movie.
   - `exceptional_movies`: Filters the top movies in terms of cast count and categorizes them.

2. **Aggregate Functions**: 
   - Uses `COUNT()` to determine the number of cast members per movie.
   - Uses `STRING_AGG()` to gather associated keywords.

3. **Window Functions**: 
   - Implements `RANK()` and `ROW_NUMBER()` to manage rankings of movies and companies.

4. **Outer Joins**: 
   - Employs `LEFT JOIN` to ensure movies without associated companies are included.

5. **Null Handling**: 
   - Uses `COALESCE` to handle cases where there may be no associated keywords, categorizing them as 'No Keywords'.

6. **Complex Logic**: 
   - The use of `CASE` statements to classify movies based on their cast sizes and to determine association status with companies.

7. **Ordering and Filtering**: 
   - The final output is ordered by production year (descending), movie category, and title for clear and organized results.
