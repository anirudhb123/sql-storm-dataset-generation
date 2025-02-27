WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_within_year
    FROM 
        aka_title a
    WHERE 
        a.production_year IS NOT NULL
),
CastDetails AS (
    SELECT 
        c.movie_id,
        c.person_id,
        p.name AS actor_name,
        COALESCE(r.role, 'Unknown') AS role_name,
        COUNT(DISTINCT c.nr_order) OVER (PARTITION BY c.movie_id) AS total_cast_members,
        CASE 
            WHEN a.title IS NOT NULL THEN 'Yes'
            ELSE 'No'
        END AS has_aka_title
    FROM 
        cast_info c
    LEFT JOIN 
        role_type r ON c.role_id = r.id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        name p ON c.person_id = p.imdb_id
),
MovieKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(mk.keyword_id) AS keyword_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieInfoAttributes AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, ', ') AS info_attributes
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    cd.actor_name,
    cd.role_name,
    cd.total_cast_members,
    mkc.keyword_count,
    mia.info_attributes,
    r.rank_within_year,
    CASE 
        WHEN mkc.keyword_count > 5 THEN 'Popular'
        WHEN mkc.keyword_count BETWEEN 1 AND 5 THEN 'Moderate'
        ELSE 'Unpopular'
    END AS popularity_status,
    COALESCE(cd.has_aka_title, 'Unknown') AS aka_title_indication
FROM 
    RankedMovies r
LEFT JOIN 
    CastDetails cd ON r.movie_id = cd.movie_id
LEFT JOIN 
    MovieKeywordCounts mkc ON r.movie_id = mkc.movie_id
LEFT JOIN 
    MovieInfoAttributes mia ON r.movie_id = mia.movie_id
WHERE 
    r.rank_within_year <= 5
    AND (r.production_year > 1990 OR cd.total_cast_members > 10)
ORDER BY 
    r.production_year DESC, 
    r.rank_within_year;

This query performs an elaborate analysis of movies within a specific schema, incorporating various SQL constructs including Common Table Expressions (CTEs), window functions, conditional logic, and aggregate functions. It ranks movies by production year, and collects cast details, keyword counts, and aggregated movie information to produce a rich dataset for performance benchmarking.
