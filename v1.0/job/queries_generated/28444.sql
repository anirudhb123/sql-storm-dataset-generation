WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        ROW_NUMBER() OVER(PARTITION BY t.id ORDER BY k.keyword) AS keyword_rank
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
), MovieCastDetails AS (
    SELECT 
        cm.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names
    FROM 
        complete_cast cm
    JOIN 
        cast_info ci ON ci.movie_id = cm.movie_id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    GROUP BY 
        cm.movie_id
), MovieInfoAggregated AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mt.info || ' (' || it.info || ')', '; ') AS detailed_info
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT
    r.movie_id,
    r.movie_title,
    r.production_year,
    mcd.cast_count,
    mcd.cast_names,
    mia.detailed_info,
    r.movie_keyword
FROM 
    RankedMovies r
JOIN 
    MovieCastDetails mcd ON r.movie_id = mcd.movie_id
JOIN 
    MovieInfoAggregated mia ON r.movie_id = mia.movie_id
WHERE
    r.keyword_rank = 1
ORDER BY 
    r.production_year DESC, 
    mcd.cast_count DESC;
