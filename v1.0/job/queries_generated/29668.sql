WITH MovieTitleDetails AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        k.keyword AS movie_keyword,
        ct.kind AS company_type
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
),
ActorDetails AS (
    SELECT 
        a.name AS actor_name,
        a.id AS actor_id,
        ci.movie_id,
        ci.nr_order
    FROM 
        aka_name a
    JOIN 
        cast_info ci ON a.person_id = ci.person_id
),
MovieActorDetails AS (
    SELECT 
        mtd.title_id,
        mtd.title,
        mtd.production_year,
        ad.actor_name,
        ad.actor_id,
        ad.nr_order
    FROM 
        MovieTitleDetails mtd
    JOIN 
        ActorDetails ad ON mtd.title_id = ad.movie_id
    ORDER BY 
        mtd.production_year DESC, ad.nr_order
)
SELECT 
    mad.title,
    mad.production_year,
    string_agg(mad.actor_name, ', ') AS actors_list
FROM 
    MovieActorDetails mad
GROUP BY 
    mad.title_id, mad.title, mad.production_year
HAVING 
    COUNT(mad.actor_id) > 1
ORDER BY 
    mad.production_year DESC, mad.title;
