WITH RankedTitles AS (
    SELECT 
        a.name AS actor_name,
        t.title AS movie_title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY t.production_year DESC) AS rank
    FROM
        aka_name a
    INNER JOIN
        cast_info c ON a.person_id = c.person_id
    INNER JOIN
        aka_title t ON c.movie_id = t.movie_id
    WHERE
        t.production_year IS NOT NULL
),
FilteredTitles AS (
    SELECT 
        actor_name,
        movie_title,
        production_year,
        CASE 
            WHEN production_year < 2000 THEN 'Old Film'
            WHEN production_year >= 2000 AND production_year <= 2010 THEN 'Recent Film'
            ELSE 'New Film'
        END AS film_category
    FROM 
        RankedTitles
    WHERE
        rank <= 3
),
MovieInfo AS (
    SELECT 
        mt.movie_id,
        GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords,
        GROUP_CONCAT(DISTINCT it.info ORDER BY it.info DESC) AS additional_info
    FROM
        movie_keyword mk
    JOIN
        keyword k ON mk.keyword_id = k.id
    JOIN
        movie_info mi ON mi.movie_id = mk.movie_id
    JOIN
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mt.movie_id
)
SELECT 
    ft.actor_name,
    ft.movie_title,
    ft.production_year,
    ft.film_category,
    COALESCE(mi.keywords, 'No keywords') AS keywords,
    COALESCE(mi.additional_info, 'No additional info') AS additional_info
FROM 
    FilteredTitles ft
LEFT JOIN 
    MovieInfo mi ON ft.movie_title = (SELECT title FROM aka_title WHERE id = (SELECT movie_id FROM cast_info WHERE person_id = (SELECT person_id FROM aka_name WHERE name = ft.actor_name LIMIT 1) LIMIT 1))
ORDER BY 
    ft.actor_name ASC, ft.production_year DESC;

-- The query above does the following:
-- 1. It creates a ranked list of movies for each actor with the latest films ranked first.
-- 2. It filters this list to only include the top 3 recent films for each actor and categorizes them.
-- 3. It aggregates keywords and additional info for each movie.
-- 4. Finally, it combines actor names, movie titles, production years, film categories, keywords, and additional info while handling NULL values gracefully with COALESCE.
-- 5. The use of subqueries and CTEs allows for dynamic creation of ranks based on respective movie years and ensures that all data fits into the calculated framework of the ranking.
