WITH RecursiveActorTitles AS (
    SELECT 
        ak.person_id,
        ak.name AS actor_name,
        at.title AS movie_title,
        ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year DESC) AS title_rank
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
),
CompanyPerformance AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        COUNT(*) AS total_companies,
        AVG(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END) AS avg_note_present
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id, cn.name
),
MoviesWithKeywords AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(k.keyword, ', ') AS keyword_list
    FROM 
        aka_title mt
    JOIN 
        movie_keyword mk ON mt.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mt.id
),
FilteredTitles AS (
    SELECT 
        rt.person_id,
        rt.actor_name,
        rt.movie_title,
        COALESCE(mk.keyword_list, 'No Keywords') AS keywords,
        cp.total_companies
    FROM 
        RecursiveActorTitles rt
    LEFT JOIN 
        MoviesWithKeywords mk ON rt.title = mk.movie_id
    LEFT JOIN 
        CompanyPerformance cp ON rt.title_rank = cp.movie_id
)
SELECT 
    DISTINCT f.actor_name,
    f.movie_title,
    f.keywords,
    f.total_companies,
    CASE 
        WHEN f.total_companies > 1 THEN 'Major Production'
        WHEN f.total_companies = 1 AND f.keywords <> 'No Keywords' THEN 'Indie Film with Keywords'
        ELSE 'Unclassified'
    END AS production_type
FROM 
    FilteredTitles f
WHERE 
    f.keywords IS NOT NULL 
    AND f.actor_name LIKE 'A%' 
    AND (f.total_companies > 2 OR f.keywords <> 'No Keywords')
ORDER BY 
    f.actor_name, f.movie_title;
