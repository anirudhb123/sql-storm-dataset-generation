WITH ranked_movies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COUNT(DISTINCT ci.person_id) AS total_actors,
        AVG(year(m.production_year)) OVER(PARTITION BY m.production_year) AS avg_year,
        ROW_NUMBER() OVER(ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank,
        COALESCE(m.production_year, 0) AS safe_production_year
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info ci ON m.movie_id = ci.movie_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.id, m.title, m.production_year
),
movies_with_demo AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.total_actors,
        rm.avg_year,
        rm.rank,
        CASE WHEN rm.rank <= 10 THEN 'Top 10 Movies'
             WHEN rm.rank <= 20 THEN 'Top 20 Movies'
             ELSE 'Other Movies' END AS demo_category
    FROM 
        ranked_movies rm
),
final_result AS (
    SELECT 
        mw.movie_id,
        mw.title,
        mw.total_actors,
        mw.demo_category,
        CASE 
            WHEN mw.total_actors IS NULL OR mw.total_actors < 5 THEN 'Less than 5 Actors'
            ELSE '5 or more Actors'
        END AS actor_count_category,
        STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
        COUNT(DISTINCT mi.info) AS info_count
    FROM 
        movies_with_demo mw
    LEFT JOIN 
        movie_keyword mk ON mw.movie_id = mk.movie_id
    LEFT JOIN 
        movie_info mi ON mw.movie_id = mi.movie_id
    WHERE 
        (mw.safe_production_year = 0 OR mw.safe_production_year BETWEEN 1900 AND 2023)
    GROUP BY 
        mw.movie_id, mw.title, mw.total_actors, mw.demo_category
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.info_count > 0 THEN 'Has Info'
        ELSE 'No Info'
    END AS info_presence,
    ROW_NUMBER() OVER(ORDER BY fr.total_actors DESC, fr.rank) AS overall_rank
FROM 
    final_result fr
WHERE 
    fr.demo_category = 'Top 10 Movies' 
    OR fr.actor_count_category = '5 or more Actors'
ORDER BY 
    fr.total_actors DESC, fr.demo_category;
