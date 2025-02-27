WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        id AS movie_id,
        title,
        production_year,
        NULL::INTEGER AS parent_id,
        1 AS level
    FROM 
        aka_title
    WHERE 
        production_year BETWEEN 1990 AND 2020
    UNION ALL
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
MovieCast AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS total_cast,
        SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) AS lead_cast
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        STRING_AGG(DISTINCT mi.info, ', ') AS info_details
    FROM 
        movie_info mi
    JOIN 
        aka_title m ON mi.movie_id = m.id
    WHERE 
        mi.note IS NULL 
    GROUP BY 
        m.movie_id
),
CombinedMovieData AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(mc.total_cast, 0) AS total_cast,
        COALESCE(mc.lead_cast, 0) AS lead_cast,
        mid.info_details
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieCast mc ON mh.movie_id = mc.movie_id 
    LEFT JOIN 
        MovieInfo mid ON mh.movie_id = mid.movie_id 
    WHERE 
        mh.level <= 3 -- Limit to direct or indirect descendants
)
SELECT 
    title, 
    production_year, 
    total_cast, 
    lead_cast, 
    info_details,
    CASE 
        WHEN total_cast = 0 THEN 'No cast'
        WHEN lead_cast > 0 THEN 'Has lead cast'
        ELSE 'Only supporting cast'
    END AS cast_summary
FROM 
    CombinedMovieData
ORDER BY 
    production_year DESC, 
    total_cast DESC 
LIMIT 100
OFFSET 20;

### Explanation of Features Used:
1. **Common Table Expressions (CTEs)**: Multiple CTEs to separate movie hierarchy, cast information, and movie details.
2. **Recursive CTE**: Used to fetch movie hierarchies (episodes related to series).
3. **Aggregations**: Used `COUNT` and `SUM` for total counts of cast members and leads.
4. **String Aggregation**: `STRING_AGG` to concatenate info details.
5. **Conditional Logic**: `CASE` statements to provide insights based on cast information.
6. **NULL Handling**: `COALESCE` to replace null values with zeros.
7. **Bizarre Elements**: The design incorporates a complex hierarchy retrieval, which can lead to deeper insights into the movie dataset. The use of outer joins adds potential for discovering additional layers or missing links in cast or related information.
