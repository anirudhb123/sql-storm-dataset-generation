WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(a.name, 'Unknown Actor') AS lead_actor,
        COUNT(DISTINCT mc.id) AS companies_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT mc.id) DESC) AS rn
    FROM 
        title t
    LEFT JOIN 
        cast_info ci ON t.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id
    WHERE 
        t.production_year IS NOT NULL
    GROUP BY 
        t.id, t.title, a.name
),
FilteredTitles AS (
    SELECT 
        *
    FROM 
        RankedMovies
    WHERE 
        rn <= 5 AND title_id IS NOT NULL
),
MovieInfo AS (
    SELECT 
        ft.title_id,
        ft.title,
        pt.info AS production_info,
        kt.keyword AS related_keyword,
        ROW_NUMBER() OVER (PARTITION BY ft.title_id ORDER BY pt.info_type_id) as keyword_rank
    FROM 
        FilteredTitles ft
    LEFT JOIN 
        movie_info mi ON ft.title_id = mi.movie_id
    LEFT JOIN 
        info_type it ON mi.info_type_id = it.id
    LEFT JOIN 
        movie_keyword mk ON ft.title_id = mk.movie_id
    LEFT JOIN 
        keyword kt ON mk.keyword_id = kt.id
    LEFT JOIN 
        person_info pt ON ft.title_id = pt.person_id AND pt.info_type_id IS NOT NULL
),
NullCheck AS (
    SELECT 
        mt.title,
        COALESCE(mt.production_info, 'No Info Available') AS production_info,
        CASE 
            WHEN mt.related_keyword IS NULL THEN 'No Keywords'
            ELSE mt.related_keyword 
        END AS keyword_info
    FROM 
        MovieInfo mt
)
SELECT 
    n.episode_nr,
    n.season_nr,
    t.title,
    n.title AS original_title,
    k.keyword AS genre,
    c.kind AS comp_cast_type,
    COALESCE(pc.name, 'Unknown') AS company_name,
    r.role,
    CASE 
        WHEN CastCount IS NULL THEN '0 Cast' 
        ELSE CastCount END AS CastCount,
    NULLIF(SUM(CASE WHEN mt.production_info IS NOT NULL THEN 1 ELSE 0 END), 0) AS valid_production_info_count
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
LEFT JOIN 
    (SELECT 
        movie_id, 
        COUNT(DISTINCT person_id) AS CastCount 
     FROM 
        cast_info 
     GROUP BY 
        movie_id) AS cast_info_count ON cast_info_count.movie_id = t.id
LEFT JOIN 
    kind_type k ON t.kind_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name pc ON mc.company_id = pc.id
LEFT JOIN 
    comp_cast_type c ON mc.company_type_id = c.id
LEFT JOIN 
    role_type r ON r.id = mc.note
LEFT JOIN 
    FilteredTitles f ON t.id = f.title_id
LEFT JOIN 
    NullCheck nc ON f.title = nc.title
WHERE 
    (t.production_year BETWEEN 2000 AND 2023 OR t.kind_id IS NULL)
    AND (f.title IS NOT NULL OR nc.keyword_info IS NOT NULL)
GROUP BY 
    n.episode_nr, n.season_nr, t.title, k.keyword, pc.name, c.kind, r.role, CastCount
ORDER BY 
    t.production_year DESC, k.kind
LIMIT 100;
