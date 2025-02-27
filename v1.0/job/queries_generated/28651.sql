WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        t.kind_id,
        RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS rank_by_cast
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year, t.kind_id
),
FilteredMovies AS (
    SELECT 
        rm.* 
    FROM 
        RankedMovies rm
    WHERE 
        rm.rank_by_cast = 1
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        t.title AS movie_title,
        t.production_year
    FROM 
        aka_name ak
    JOIN 
        cast_info c ON ak.person_id = c.person_id
    JOIN 
        FilteredMovies t ON c.movie_id = t.movie_id
)
SELECT 
    ad.actor_name,
    ad.movie_title,
    ad.production_year,
    COUNT(DISTINCT ct.kind) AS company_types
FROM 
    ActorDetails ad
JOIN 
    movie_companies mc ON ad.movie_title = (SELECT title FROM aka_title WHERE id = mc.movie_id)
JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    ad.actor_name, ad.movie_title, ad.production_year
ORDER BY 
    ad.production_year DESC, ad.actor_name;

This query effectively performs a benchmark on string processing involving multiple tables with a focus on titles, cast members, and their associated companies. It ranks movies by the number of cast members, retrieves titles of those movies produced in the same year, and counts the distinct company types associated with those movies, providing interesting insights into the actors’ filmographies in terms of production characteristics.
