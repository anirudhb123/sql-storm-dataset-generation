WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword AS keyword,
        COUNT(DISTINCT c.person_id) AS actor_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, k.keyword
), 

CompanyDetails AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
), 

ActorInfo AS (
    SELECT 
        ak.name AS actor_name,
        a.imdb_index AS actor_imdb_index,
        a.gender AS actor_gender,
        ci.movie_id
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        name a ON ak.person_id = a.imdb_id
    WHERE 
        a.gender = 'F'
), 

MovieActorCompany AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.keyword,
        md.actor_count,
        ca.actor_name,
        ca.actor_imdb_index,
        ca.actor_gender,
        co.company_name,
        co.company_type
    FROM 
        MovieDetails md
    JOIN 
        ActorInfo ca ON md.movie_id = ca.movie_id
    JOIN 
        CompanyDetails co ON md.movie_id = co.movie_id
)

SELECT 
    movie_id,
    title,
    production_year,
    keyword,
    actor_count,
    actor_name,
    actor_imdb_index,
    actor_gender,
    company_name,
    company_type
FROM 
    MovieActorCompany
ORDER BY 
    production_year DESC, 
    title, 
    actor_name;
