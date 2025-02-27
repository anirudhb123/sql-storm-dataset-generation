WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieCTE c ON ml.movie_id = c.movie_id
    WHERE 
        c.level < 3
), FilteredMovies AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS num_cast_members,
        AVG(CASE WHEN mi.info_type_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_info_available
    FROM 
        MovieCTE m
    LEFT JOIN 
        cast_info c ON m.movie_id = c.movie_id
    LEFT JOIN 
        movie_info mi ON m.movie_id = mi.movie_id
    GROUP BY 
        m.movie_id, m.title, m.production_year
), RankedMovies AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY num_cast_members DESC, production_year ASC) AS rank
    FROM 
        FilteredMovies
)
SELECT 
    r.title, 
    r.production_year, 
    r.num_cast_members,
    r.avg_info_available,
    COALESCE(cn.name, 'Unknown') AS company_name,
    COALESCE(k.keyword, 'N/A') AS movie_keyword
FROM 
    RankedMovies r
LEFT JOIN 
    movie_companies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    r.rank <= 10
ORDER BY 
    r.rank
;

This SQL query benchmarks performance over a dataset by combining multiple advanced SQL concepts. It starts by establishing a recursive common table expression (CTE) called `MovieCTE` to retrieve movies produced after 2000 and their linked sequels (depth limit of 2). Then it filters these movies, counting distinct cast members and averaging available information. The results are ranked, and the final selection pulls in company names and associated keywords while handling potential NULLs gracefully. The output is limited to the top 10 movies based on the number of cast members.
