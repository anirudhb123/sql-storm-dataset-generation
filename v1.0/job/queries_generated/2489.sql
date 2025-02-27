WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
),
CastInfoWithRole AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        ci.role_id,
        rt.role
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MovieCompaniesWithGenres AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT kt.keyword, ', ') AS genres
    FROM 
        movie_companies mc
    JOIN 
        movie_keyword mk ON mc.movie_id = mk.movie_id
    JOIN 
        keyword kt ON mk.keyword_id = kt.id
    GROUP BY 
        mc.movie_id
),
PersonMovieInfo AS (
    SELECT
        pi.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT t.title, ', ') AS movies
    FROM 
        person_info pi
    LEFT JOIN 
        cast_info ci ON pi.person_id = ci.person_id
    LEFT JOIN 
        title t ON ci.movie_id = t.id
    GROUP BY 
        pi.person_id
)
SELECT 
    at.title,
    at.production_year,
    COALESCE(gt.genres, 'Unknown') AS genres,
    r.name AS actor_name,
    pi.movie_count,
    pi.movies
FROM 
    RankedTitles at
LEFT JOIN 
    MovieCompaniesWithGenres gt ON at.title_id = gt.movie_id
LEFT JOIN 
    CastInfoWithRole ci ON at.title_id = ci.movie_id
LEFT JOIN 
    aka_name r ON ci.person_id = r.person_id
LEFT JOIN 
    PersonMovieInfo pi ON pi.person_id = ci.person_id
WHERE 
    at.production_year >= 2000
    AND (ci.role IS NOT NULL OR pi.movie_count > 0)
ORDER BY 
    at.production_year DESC, at.title;
