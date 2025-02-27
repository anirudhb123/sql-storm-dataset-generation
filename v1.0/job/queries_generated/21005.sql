WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank_title,
        COUNT(DISTINCT ci.person_id) AS total_cast
    FROM 
        aka_title t
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CastDetails AS (
    SELECT
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS distinct_actors,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.note IS NULL
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT
        mk.movie_id,
        km.keyword,
        mi.info
    FROM 
        movie_keyword mk
    JOIN 
        keyword km ON mk.keyword_id = km.id
    LEFT JOIN 
        movie_info mi ON mk.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
),
AverageCastingStats AS (
    SELECT 
        production_year,
        AVG(total_cast) AS avg_cast_size
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)
SELECT 
    tm.title AS movie_title,
    COALESCE(cd.distinct_actors, 0) AS number_of_actors,
    CASE 
        WHEN rm.rank_title IS NULL THEN 'Not Ranked' 
        ELSE CONCAT('Ranked #: ', rm.rank_title) 
    END AS ranking,
    mv_info.info AS plot_information,
    mv_info.keyword AS movie_keyword,
    ac.avg_cast_size
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
LEFT JOIN 
    MovieInfo mv_info ON rm.movie_id = mv_info.movie_id
LEFT JOIN 
    AverageCastingStats ac ON rm.production_year = ac.production_year
WHERE 
    rm.production_year >= 2000 
    AND (cd.distinct_actors > 5 OR cd.distinct_actors IS NULL)
ORDER BY 
    rm.production_year DESC, 
    mv_info.keyword ASC NULLS LAST; 

### Explanation:
1. **Common Table Expressions (CTEs)**:
   - **RankedMovies**: Retrieves movies with a rank based on their titles for each year and calculates total cast.
   - **CastDetails**: Aggregates actors for each movie, filtering out any cast notes/NULL.
   - **MovieInfo**: Joins keywords with plot information for movies.
   - **AverageCastingStats**: Computes average cast size for each production year.

2. **Main Query**: 
   - Selects movie titles, actor counts, rankings, plot information, keywords alongside average cast size, all while managing NULLs gracefully and maintaining a certain order.

3. **Filters**: 
   - Limits results to productions from the year 2000 onwards, considers distinct actor counts, allowing for potentially NULL values.

4. **Ordering**: 
   - Orders by production year descending and keyword in an ascending order that places NULLs last, showcasing a hierarchical structure. 

This query combines various SQL functionalities and nuances while also addressing complex scenarios and conditions data might present.
