WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(c.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(CONCAT(a.name, ' as ', rt.role) ORDER BY ci.nr_order) AS cast_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        MAX(CASE WHEN it.info = 'Synopsis' THEN mi.info END) AS synopsis,
        MAX(CASE WHEN it.info = 'Rating' THEN mi.info END) AS rating
    FROM 
        movie_info mi
    JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
)
SELECT 
    t.title AS Movie_Title,
    t.production_year AS Production_Year,
    cd.company_names AS Production_Companies,
    cd.company_types AS Company_Types,
    ca.cast_count AS Total_Cast,
    ca.cast_roles AS Actors_Roles,
    mi.synopsis AS Movie_Synopsis,
    mi.rating AS Movie_Rating
FROM 
    RankedTitles t
LEFT JOIN 
    CompanyDetails cd ON t.title_id = cd.movie_id
LEFT JOIN 
    CastDetails ca ON t.title_id = ca.movie_id
LEFT JOIN 
    MovieInfo mi ON t.title_id = mi.movie_id
WHERE 
    (mi.rating IS NOT NULL AND (mi.rating::NUMERIC >= 8 OR mi.synopsis LIKE '%award%')) OR
    (mi.rating IS NULL AND t.production_year < 2000)
ORDER BY 
    t.production_year DESC, 
    t.title;

