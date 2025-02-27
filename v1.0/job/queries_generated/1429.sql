WITH MovieRatings AS (
    SELECT 
        ma.movie_id,
        AVG(ri.rating) AS avg_rating,
        COUNT(ri.id) AS rating_count
    FROM 
        movie_info mi
    JOIN 
        movie_info_idx rii ON mi.id = rii.movie_id
    JOIN 
        (SELECT 
             movie_id,
             rating
         FROM 
             ratings_info) ri ON mi.movie_id = ri.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
    GROUP BY 
        ma.movie_id
), ActorFilmography AS (
    SELECT 
        ak.name,
        ak.id AS actor_id,
        ct.kind AS role,
        at.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY at.production_year DESC) AS rn
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        aka_title at ON ci.movie_id = at.movie_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
), CompanyMovies AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    af.actor_id,
    af.name AS actor_name,
    af.title AS movie_title,
    af.production_year,
    IFNULL(mr.avg_rating, 0) AS average_rating,
    cmm.companies AS production_companies,
    af.role,
    af.rn
FROM 
    ActorFilmography af
LEFT JOIN 
    MovieRatings mr ON af.movie_id = mr.movie_id
LEFT JOIN 
    CompanyMovies cmm ON af.movie_id = cmm.movie_id
WHERE 
    af.rn <= 3
ORDER BY 
    af.actor_name, af.production_year DESC;
