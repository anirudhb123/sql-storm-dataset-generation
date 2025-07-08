
WITH RankedTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER(PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        a.person_id,
        a.name,
        COUNT(DISTINCT c.movie_id) AS movies_count
    FROM 
        aka_name a
    LEFT JOIN 
        cast_info c ON a.person_id = c.person_id
    GROUP BY 
        a.person_id, a.name
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rt.title,
    rt.production_year,
    ad.name AS actor_name,
    COALESCE(ad.movies_count, 0) AS total_movies,
    cd.companies,
    kd.keywords
FROM 
    RankedTitles rt
LEFT JOIN 
    ActorDetails ad ON rt.title_id = ad.person_id
LEFT JOIN 
    CompanyDetails cd ON rt.title_id = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON rt.title_id = kd.movie_id
WHERE 
    rt.year_rank <= 5 
    AND (ad.movies_count IS NULL OR ad.movies_count > 2)
ORDER BY 
    rt.production_year DESC, rt.title;
