WITH RankedTitles AS (
    SELECT 
        title.id AS title_id,
        title.title,
        title.production_year,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY title.title) AS rn,
        COUNT(*) OVER (PARTITION BY title.production_year) AS total_titles
    FROM 
        title
    WHERE 
        title.production_year IS NOT NULL
),
MaxProductionYear AS (
    SELECT 
        MAX(production_year) AS max_year
    FROM 
        title
),
MoviesWithKeywords AS (
    SELECT 
        aka_title.title,
        movie_keyword.keyword_id,
        keyword.keyword,
        aka_title.production_year
    FROM 
        aka_title
    LEFT JOIN 
        movie_keyword ON aka_title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        aka_title.production_year = (SELECT max_year FROM MaxProductionYear)
),
MovieCastRoles AS (
    SELECT 
        cast_info.movie_id, 
        role_type.role,
        COUNT(cast_info.person_id) AS num_cast
    FROM 
        cast_info
    JOIN 
        role_type ON cast_info.role_id = role_type.id
    GROUP BY 
        cast_info.movie_id, 
        role_type.role
),
FilteredCastInfo AS (
    SELECT 
        ci.movie_id,
        ci.person_id,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_cast
    FROM 
        cast_info ci
    WHERE 
        ci.note IS NULL OR ci.note LIKE '%main%'
),
FinalResults AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword,
        mc.num_cast AS cast_count,
        COALESCE(fc.total_cast, 0) AS filtered_cast_count,
        COUNT(DISTINCT a.name) AS alias_count
    FROM 
        RankedTitles rt
    JOIN 
        aka_title t ON rt.title_id = t.id
    LEFT JOIN 
        MoviesWithKeywords k ON t.title = k.title AND t.production_year = k.production_year
    JOIN 
        MovieCastRoles mc ON t.id = mc.movie_id
    LEFT JOIN 
        FilteredCastInfo fc ON t.id = fc.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id IN (SELECT ci.person_id FROM cast_info ci WHERE ci.movie_id = t.id)
    WHERE 
        rt.rn <= 5 AND 
        rt.total_titles > 10 AND 
        t.production_year IS NOT NULL
    GROUP BY 
        t.title, 
        t.production_year, 
        k.keyword, 
        mc.num_cast, 
        fc.total_cast
)
SELECT 
    movie_title, 
    production_year, 
    keyword, 
    cast_count, 
    filtered_cast_count, 
    alias_count
FROM 
    FinalResults
ORDER BY 
    production_year DESC, 
    movie_title;

