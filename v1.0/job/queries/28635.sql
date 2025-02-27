
WITH MovieTitles AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword
    FROM 
        aka_title t
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year >= 2000
),
ActorDetails AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ci.movie_id,
        ci.role_id,
        ci.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
    WHERE 
        a.name LIKE '%Smith%'
),
MovieCompanyDetails AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(cn.name, ', ') AS company_names,
        STRING_AGG(ct.kind, ', ') AS company_types
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    mt.title_id,
    mt.title,
    mt.production_year,
    ad.actor_name,
    ad.nr_order,
    mcd.company_names,
    mcd.company_types,
    COUNT(mk.id) AS keyword_count
FROM 
    MovieTitles mt
JOIN 
    ActorDetails ad ON mt.title_id = ad.movie_id
LEFT JOIN 
    MovieCompanyDetails mcd ON mt.title_id = mcd.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.title_id = mk.movie_id
GROUP BY 
    mt.title_id, mt.title, mt.production_year, ad.actor_name, ad.nr_order, mcd.company_names, mcd.company_types
ORDER BY 
    mt.production_year DESC, keyword_count DESC, ad.nr_order ASC;
