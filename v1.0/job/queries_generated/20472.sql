WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_order
    FROM 
        title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ak.person_id,
        ak.name,
        c.movie_id,
        COALESCE(c.nr_order, 0) AS actor_order,
        COUNT(c.movie_id) OVER (PARTITION BY ak.person_id) AS total_movies
    FROM 
        aka_name ak
    LEFT JOIN 
        cast_info c ON ak.person_id = c.person_id
),
FlexibleSearch AS (
    SELECT 
        DISTINCT ak.name,
        ak.md5sum AS name_md5,
        t.title,
        t.production_year,
        k.keyword,
        CASE 
            WHEN cc.kind IS NULL THEN 'Other'
            ELSE cc.kind
        END AS company_category
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        movie_companies mc ON mc.movie_id = ci.movie_id
    LEFT JOIN 
        company_type cc ON mc.company_type_id = cc.id
    LEFT JOIN 
        movie_keyword mk ON mk.movie_id = ci.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        ak.name IS NOT NULL OR
        t.production_year >= 2000
),
FinalOutput AS (
    SELECT 
        ad.person_id,
        ad.name,
        rt.title,
        rt.production_year,
        ad.total_movies,
        f.company_category
    FROM 
        ActorDetails ad
    JOIN 
        RankedTitles rt ON ad.movie_id = rt.title_id
    JOIN 
        FlexibleSearch f ON ad.name = f.name
    WHERE 
        ad.actor_order < 5 OR
        f.company_category = 'Distributor'
)
SELECT 
    fo.person_id,
    fo.name,
    fo.title,
    fo.production_year,
    fo.total_movies,
    COALESCE(fo.company_category, 'Unknown') AS final_company_category
FROM 
    FinalOutput fo
ORDER BY 
    fo.production_year DESC, 
    fo.total_movies DESC;
